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

    if (ok) {
      std::ofstream output_file(save_path);
      free(save_path);
      std::ofstream FILE(save_path, std::ofstream::binary);
      std::copy(output.begin(),
		output.end(),
		std::ostreambuf_iterator<char>(FILE));
      CAMLreturn(Val_unit);
    } else {
      free(save_path);
      caml_failwith("Decompression Error");
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

    if (ok) {
      as_bigarray = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
				  1,
				  output.data(),
				  dims);
      CAMLreturn(as_bigarray);
    } else {
      caml_failwith("Decompression Error");
    }
  }

  CAMLprim value brotli_ml_compress_path(value file_dest, value this_barray)
  {
    CAMLparam2(file_dest, this_barray);

    char *write_to_path = caml_strdup(String_val(file_dest));
    int ok;

    uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t size = Caml_ba_array_val(this_barray)->dim[0];

    BrotliParams::Mode mode = (BrotliParams::Mode) 0;

    free(write_to_path);
    CAMLreturn(Val_unit);
  }

  CAMLprim value brotli_ml_compress_in_mem(value this_barray)
  {
    CAMLparam1(this_barray);

    uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t size = Caml_ba_array_val(this_barray)->dim[0];

    BrotliParams::Mode mode = (BrotliParams::Mode) 0;
    BrotliParams params;
    params.mode = mode;


    CAMLreturn(this_barray);
  }

  CAMLprim value brotli_ml_compress_to_bytes(value this_data)
  {
    CAMLparam1(this_data);

    BrotliParams::Mode mode = (BrotliParams::Mode) 0;
    BrotliParams params;
    params.mode = mode;
    params.quality = 2;
    params.lgwin = 10;
    params.lgblock = 20;

    /* ok = BrotliCompressBuffer(params, length, input, */
    /* 			      &output_length, output); */

    CAMLreturn(caml_copy_string("42"));
  }
}
