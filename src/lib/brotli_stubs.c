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
#include <caml/callback.h>
// Brotli itself
#include <brotli/decode.h>

#include <vector>

extern "C" {

  int output_callback(void *data, const uint8_t *buf, size_t count)
  {
    std::vector<uint8_t> *output = (std::vector<uint8_t> *)data;
    output->insert(output->end(), buf, buf + count);
    return (int)count;
  }

  CAMLprim value brotli_ml_decompress_buffer(value compressed_buffer)
  {
    CAMLparam1(compressed_buffer);
    uint8_t *input;
    size_t length;
    int ok;

    length = caml_string_length(compressed_buffer);
    input = (unsigned char *)caml_strdup(String_val(compressed_buffer));

    BrotliMemInput memin;
    BrotliInput in = BrotliInitMemInput(input, length, &memin);

    BrotliOutput out;
    std::vector<uint8_t> output;

    out.cb_ = &output_callback;
    out.data_ = &output;

    ok = BrotliDecompress(in, out);
    printf("len: %d, Result %d\n", length, ok);
    if (ok) {
      char *result = (char*)output.data();
      CAMLreturn(caml_copy_string(result));
    } else {
      caml_failwith("Decompression error");
    }
  }
}
