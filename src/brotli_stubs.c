//Standard C
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>
// OCaml declarations
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/signals.h>
// Brotli itself
#include <brotli/dec/decode.h>
#include <brotli/enc/encode.h>
//C++
#include <vector>
#include <string>
#include <fstream>
#include <algorithm>
#include <iostream>
#include <iterator>

using namespace brotli;

extern "C" {

  int output_callback(void *data, const uint8_t *buf, size_t count)
  {
    std::vector<uint8_t> *output = (std::vector<uint8_t> *)data;
    output->insert(output->end(), buf, buf + count);
    return (int)count;
  }

  CAMLprim value brotli_ml_decompress_path(value file_dest, value this_barray)
  {
    CAMLparam2(file_dest, this_barray);
    int ok;
    char *save_path = caml_strdup(String_val(file_dest));

    uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
    // Since this is only 1 dimensional array, we only check the 0th entry.
    size_t size = Caml_ba_array_val(this_barray)->dim[0];

    BrotliMemInput memin;
    BrotliInput in = BrotliInitMemInput(raw_data, size, &memin);
    BrotliOutput out;
    std::vector<uint8_t> output;

    out.cb_ = &output_callback;
    out.data_ = &output;

    caml_enter_blocking_section();
    ok = BrotliDecompress(in, out);
    caml_leave_blocking_section();

    raw_data = NULL;

    switch (ok) {
    case 1: {
      std::ofstream FILE(save_path, std::ofstream::binary | std::ofstream::out);
      std::copy(output.begin(),
		output.end(),
		std::ostreambuf_iterator<char>(FILE));
      free(save_path);
      FILE.close();
      CAMLreturn(Val_unit);
    }
    case 0: {
      free(save_path);
      caml_failwith("Decoding error, e.g. corrupt input or no memory");
    }
    case 2: {
      free(save_path);
      caml_failwith("Partially done, but must be called again with more input");
    }
    case 3: {
      free(save_path);
      caml_failwith("Partially done, but must be called again with more output");
    }
    default: {
      free(save_path);
      caml_failwith("Decompression Error");
    }
    }
  }

  CAMLprim value brotli_ml_decompress_in_mem(value this_barray)
  {
    CAMLparam1(this_barray);
    CAMLlocal1(as_bigarray);

    int ok;
    uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t size = Caml_ba_array_val(this_barray)->dim[0];

    BrotliMemInput memin;
    BrotliInput in = BrotliInitMemInput(raw_data, size, &memin);
    BrotliOutput out;
    std::vector<uint8_t> output;

    out.cb_ = &output_callback;
    out.data_ = &output;

    caml_enter_blocking_section();
    ok = BrotliDecompress(in, out);
    caml_leave_blocking_section();

    long dims[0];
    dims[0] = output.size();

    raw_data = NULL;
    switch (ok) {
    case 1: {
      as_bigarray = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
				  1,
				  output.data(),
				  dims);
      CAMLreturn(as_bigarray);
    }
    case 0:
      caml_failwith("Decoding error, e.g. corrupt input or no memory");
    case 2:
      caml_failwith("Partially done, but must be called again with more input");
    case 3:
      caml_failwith("Partially done, but must be called again with more output");
    default:
      caml_failwith("Decompression Error");
    }
  }

  CAMLprim value brotli_ml_compress_path(value file_dest,
					 value ml_params,
					 value this_barray)
  {
    CAMLparam3(file_dest, ml_params, this_barray);

    char *save_path = caml_strdup(String_val(file_dest));
    int ok;

    uint8_t *input = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t length = Caml_ba_array_val(this_barray)->dim[0];

    size_t output_length = 1.2 *  length + 10240;
    uint8_t *output = new uint8_t[output_length];

    BrotliParams params;
    params.mode = (BrotliParams::Mode)Int_val(Field(ml_params, 0));
    params.quality = Int_val(Field(ml_params, 1));
    params.lgwin = Int_val(Field(ml_params, 2));
    params.lgblock = Int_val(Field(ml_params, 3));

    BrotliMemIn *n = new BrotliMemIn(input, length);
    BrotliMemOut *o = new BrotliMemOut(output, output_length);

    caml_enter_blocking_section();
    ok = BrotliCompress(params, n, o);
    caml_leave_blocking_section();

    delete n;
    delete o;
    input = NULL;
    if (ok) {
      std::ofstream FILE(save_path, std::ofstream::binary | std::ofstream::out);
      std::copy(output,
      		output + output_length,
      		std::ostreambuf_iterator<char>(FILE));
      FILE.close();
      delete[] output;
      free(save_path);
      CAMLreturn(Val_unit);
    } else {
      delete[] output;
      free(save_path);
      caml_failwith("Compression Error");
    }
  }

  CAMLprim value brotli_ml_compress_in_mem(value ml_params,
					   value this_barray)
  {
    CAMLparam2(ml_params, this_barray);
    CAMLlocal1(as_bigarray);
    int ok;

    uint8_t *input = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t length = Caml_ba_array_val(this_barray)->dim[0];
    size_t output_length = 1.2 *  length + 10240;
    uint8_t *output = new uint8_t[output_length];

    BrotliParams params;
    params.mode = (BrotliParams::Mode)Int_val(Field(ml_params, 0));
    params.quality = Int_val(Field(ml_params, 1));
    params.lgwin = Int_val(Field(ml_params, 2));
    params.lgblock = Int_val(Field(ml_params, 3));

    BrotliMemIn *n = new BrotliMemIn(input, length);
    BrotliMemOut *o = new BrotliMemOut(output, output_length);

    caml_enter_blocking_section();
    ok = BrotliCompress(params, n, o);
    caml_leave_blocking_section();

    delete n;
    delete o;
    input = NULL;

    long dims[0];
    dims[0] = output_length;

    if (ok) {
      as_bigarray = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
				  1,
				  output,
				  dims);
      delete[] output;
      CAMLreturn(as_bigarray);
    } else {
      delete[] output;
      caml_failwith("Compression Error");
    }
  }
}
