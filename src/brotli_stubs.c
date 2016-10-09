// -*- c++ -*-

// OCaml declarations
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/signals.h>
// Brotli itself
#include <brotli/decode.h>
#include <brotli/encode.h>
//C++
#include <cstdlib>
#include <vector>
#include <string>
#include <fstream>
#include <algorithm>
#include <iostream>
#include <iterator>

#define Val_none Val_int(0)

extern "C" {

  // int output_callback(void *data, const uint8_t *buf, size_t count)
  // {
  //   std::vector<uint8_t> *output = (std::vector<uint8_t> *)data;
  //   output->insert(output->end(), buf, buf + count);
  //   return (int)count;
  // }

  // CAMLprim value brotli_ml_decompress_path(value file_dest, value this_barray)
  // {
  //   CAMLparam2(file_dest, this_barray);
  //   int ok;
  //   char *save_path = caml_strdup(String_val(file_dest));

  //   uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
  //   // Since this is only 1 dimensional array, we only check the 0th entry.
  //   size_t size = Caml_ba_array_val(this_barray)->dim[0];

  //   BrotliMemInput memin;
  //   BrotliInput in = BrotliInitMemInput(raw_data, size, &memin);
  //   BrotliOut out;
  //   std::vector<uint8_t> output;

  //   out.cb_ = &output_callback;
  //   out.data_ = &output;

  //   caml_enter_blocking_section();
  //   ok = BrotliDecompress(in, out);
  //   caml_leave_blocking_section();

  //   raw_data = NULL;

  //   switch (ok) {
  //   case 1: {
  //     std::ofstream FILE(save_path, std::ofstream::binary | std::ofstream::out);
  //     std::copy(output.begin(),
  // 		output.end(),
  // 		std::ostreambuf_iterator<char>(FILE));
  //     free(save_path);
  //     FILE.close();
  //     CAMLreturn(Val_unit);
  //   }
  //   case 0: {
  //     free(save_path);
  //     caml_failwith("Decoding error, e.g. corrupt input or no memory");
  //   }
  //   case 2: {
  //     free(save_path);
  //     caml_failwith("Partially done, but must be called again with more input");
  //   }
  //   case 3: {
  //     free(save_path);
  //     caml_failwith("Partially done, but must be called again with more output");
  //   }
  //   default: {
  //     free(save_path);
  //     caml_failwith("Decompression Error");
  //   }
  //   }
  // }

  CAMLprim value brotli_ml_decompress_in_mem(value custom_data_dict,
					     value this_barray)
  {
    CAMLparam2(custom_data_dict, this_barray);
    CAMLlocal1(as_bigarray);

    const size_t kBufferSize = 65536;
    const uint8_t *input = NULL;
    uint8_t *buffer = new uint8_t[kBufferSize];

    BrotliState *state = BrotliCreateState(0, 0, 0);

    uint8_t *raw_data = (uint8_t*)Caml_ba_data_val(this_barray);
    size_t length = Caml_ba_array_val(this_barray)->dim[0];

    std::vector<uint8_t> output;

    BrotliResult result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
    caml_enter_blocking_section();
    while (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
      size_t available_out = kBufferSize;
      uint8_t *next_out = buffer;
      size_t total_out = 0;
      result = BrotliDecompressStream(&length,
				      &input,
				      &available_out,
				      &next_out,
				      &total_out,
				      state);
      size_t used_out = kBufferSize - available_out;
      if (used_out != 0)
	output.insert(output.end(), buffer, buffer + used_out);
    }
    caml_leave_blocking_section();
    bool ok = result == BROTLI_RESULT_SUCCESS;
    long dims[1] = {static_cast<long>(output.size())};

    if (ok) {
      printf("Supposed to be okay?\n");
      as_bigarray = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
    				  1,
    				  output.data(),
    				  dims);
      CAMLreturn(as_bigarray);
    }
    else {
      caml_failwith("Decompression Error");
    }
  }

  // CAMLprim value brotli_ml_compress_path(value file_dest,
  // 					 value ml_params,
  // 					 value this_barray)
  // {
  //   CAMLparam3(file_dest, ml_params, this_barray);

  //   char *save_path = caml_strdup(String_val(file_dest));
  //   int ok;

  //   uint8_t *input = (uint8_t*)Caml_ba_data_val(this_barray);
  //   size_t length = Caml_ba_array_val(this_barray)->dim[0];

  //   size_t output_length = 1.2 *  length + 10240;
  //   uint8_t *output = new uint8_t[output_length];

  //   BrotliParams params;
  //   params.mode = (BrotliParams::Mode)Int_val(Field(ml_params, 0));
  //   params.quality = Int_val(Field(ml_params, 1));
  //   params.lgwin = Int_val(Field(ml_params, 2));
  //   params.lgblock = Int_val(Field(ml_params, 3));

  //   BrotliMemIn *n = new BrotliMemIn(input, length);
  //   BrotliMemOut *o = new BrotliMemOut(output, output_length);

  //   caml_enter_blocking_section();
  //   ok = BrotliCompress(params, n, o);
  //   caml_leave_blocking_section();

  //   delete n;
  //   delete o;
  //   input = NULL;
  //   if (ok) {
  //     std::ofstream FILE(save_path, std::ofstream::binary | std::ofstream::out);
  //     std::copy(output,
  //     		output + output_length,
  //     		std::ostreambuf_iterator<char>(FILE));
  //     FILE.close();
  //     delete[] output;
  //     free(save_path);
  //     CAMLreturn(Val_unit);
  //   } else {
  //     delete[] output;
  //     free(save_path);
  //     caml_failwith("Compression Error");
  //   }
  // }

  CAMLprim value brotli_ml_compress_in_mem(value custom_dict_opt,
					   value ml_params,
  					   value this_barray)
  {
    CAMLparam3(custom_dict_opt, ml_params, this_barray);
    CAMLlocal1(as_bigarray);

    size_t
      length,
      output_length,
      custom_dictionary_length,
      available_in,
      available_out;

    const uint8_t *next_in = NULL;
    uint8_t *next_out = NULL;

    uint8_t *input = (uint8_t*)Caml_ba_data_val(this_barray);
    length = Caml_ba_array_val(this_barray)->dim[0];
    output_length = length + (length >> 2) + 10240;

    BrotliEncoderState *enc = BrotliEncoderCreateInstance(0, 0, 0);

    uint8_t *output = new uint8_t[output_length];

    BrotliEncoderSetParameter(enc, BROTLI_PARAM_MODE, Int_val(Field(ml_params, 0)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_QUALITY,Int_val(Field(ml_params, 1)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_LGWIN, Int_val(Field(ml_params, 2)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_LGBLOCK,Int_val(Field(ml_params, 3)));

    if (custom_dict_opt != Val_none) {
      custom_dictionary_length = Caml_ba_array_val(Field(custom_dict_opt, 0))->dim[0];
      BrotliEncoderSetCustomDictionary(enc,
				       custom_dictionary_length,
				       (uint8_t*)Caml_ba_data_val(Field(custom_dict_opt, 0)));
    }

    available_out = output_length;
    next_out = output;
    available_in = length;
    next_in = input;

    caml_enter_blocking_section();
    // no known conversion from 'const uint8_t **' (aka 'const
    // unsigned char **') to 'uint8_t **' (aka 'unsigned char **')
    BrotliEncoderCompressStream(enc,
				BROTLI_OPERATION_FINISH,
				&available_in,
				&next_in,
				&available_out,
				&next_out,
				0);
    caml_leave_blocking_section();
    bool ok = BrotliEncoderIsFinished(enc);
    BrotliEncoderDestroyInstance(enc);

    long dims[1] = {static_cast<long>(output_length - available_out)};

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
