// -*- c++ -*-

// OCaml declarations
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/signals.h>
// Brotli itself via libbrotli https://github.com/bagder/libbrotli
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

  CAMLprim value ml_brotli_compress(value dict_opt,
				    value params,
				    value compress_me)
  {
    CAMLparam3(dict_opt, params, compress_me);
    CAMLlocal1(compressed_string);

    uint8_t
      *input = (uint8_t*)String_val(compress_me),
      *output = nullptr,
      *custom_dictionary = nullptr,
      *next_out = nullptr;
    size_t
      length = caml_string_length(compress_me),
      output_length = length + (length >> 2) + 10240,
      custom_dictionary_length = 0,
      available_in = 0,
      available_out = 0;
    const uint8_t *next_in = nullptr;

    auto *enc = BrotliEncoderCreateInstance(nullptr, nullptr, nullptr);
    output = new uint8_t[output_length];

    // Setting the compression parameters
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_MODE, Int_val(Field(params, 0)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_QUALITY, Int_val(Field(params, 1)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_LGWIN, Int_val(Field(params, 2)));
    BrotliEncoderSetParameter(enc, BROTLI_PARAM_LGBLOCK, Int_val(Field(params, 3)));

    if ((dict_opt == Val_none) == false) {
      custom_dictionary = (uint8_t *)String_val(Field(dict_opt, 0));
      custom_dictionary_length = caml_string_length(Field(dict_opt, 0));
      BrotliEncoderSetCustomDictionary(enc,
				       custom_dictionary_length,
				       custom_dictionary);
    }

    available_out = output_length;
    next_out = output;
    available_in = length;
    next_in = input;

    caml_enter_blocking_section();
    BrotliEncoderCompressStream(enc,
				BROTLI_OPERATION_FINISH,
				&available_in,
				&next_in,
				&available_out,
				&next_out,
				0);
    caml_leave_blocking_section();

    bool result_is_good = BrotliEncoderIsFinished(enc);
    BrotliEncoderDestroyInstance(enc);

    if (result_is_good) {
      size_t compressed_size = output_length - available_out;
      compressed_string = caml_alloc_string(compressed_size);
      memmove(String_val(compressed_string), output, compressed_size);
      delete[] output;
      CAMLreturn(compressed_string);
    } else {
      delete[] output;
      caml_failwith("Compression failure");
    }
  }

  CAMLprim value ml_brotli_decompress(value dict_opt, value decompress_me)
  {
    CAMLparam2(dict_opt, decompress_me);
    CAMLlocal1(decompressed_string);

    const uint8_t
      *input = (uint8_t*)String_val(decompress_me),
      *custom_dictionary = nullptr;
    size_t
      length = caml_string_length(decompress_me),
      custom_dictionary_length = 0;

    printf("Length is: %ld\n", length);
    std::vector<uint8_t> output;
    const size_t kBufferSize = 65536;
    uint8_t *buffer = new uint8_t[kBufferSize];
    auto *state = BrotliCreateState(nullptr, nullptr, nullptr);

    BrotliResult result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;

    if ((dict_opt == Val_none) == false) {
      custom_dictionary = (uint8_t *)String_val(Field(dict_opt, 0));
      custom_dictionary_length = caml_string_length(Field(dict_opt, 0));
      BrotliSetCustomDictionary(custom_dictionary_length,
				custom_dictionary,
				state);
    }

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
      // printf("Brotli Result: %s\n", input);
      size_t used_out = kBufferSize - available_out;
      if (used_out != 0)
	output.insert(output.end(), buffer, buffer + used_out);
    }
    caml_leave_blocking_section();

    if ((result == BROTLI_RESULT_SUCCESS) == true) {
      decompressed_string = caml_alloc_string(output.size());
      memmove(String_val(decompressed_string), &output[0], output.size());
      BrotliDestroyState(state);
      CAMLreturn(decompressed_string);
    } else {
      delete[] buffer;
      BrotliDestroyState(state);
      caml_failwith(BrotliErrorString(BrotliGetErrorCode(state)));
    }

  }

}
