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
// Brotli itself
#include <brotli/decode.h>

#include <vector>
#include <string>

extern "C" {

  int output_callback(void *data, const uint8_t *buf, size_t count)
  {
    std::vector<uint8_t> *output = (std::vector<uint8_t> *)data;
    output->insert(output->end(), buf, buf + count);
    return (int)count;
  }

  struct result {
    size_t len;
    uint8_t *data;
  };

  static result pull_all_data(FILE *f)
  {
    int size = 0;
    fseek(f, 0, SEEK_END);
    fflush(f);
    size = ftell(f);
    rewind(f);
    fflush(f);
    uint8_t *buffer = (uint8_t *)malloc(size);
    fread(buffer, size, 1, f);
    fflush(f);
    return (struct result) {.len = static_cast<size_t>(size), .data = buffer};
  }

  CAMLprim value brotli_ml_decompress_paths(value this_barray)
  {
    CAMLparam1(this_barray);
    printf("Called big array\n");
    CAMLreturn(Val_unit);
  }

  CAMLprim value brotli_ml_decompress_buffer(value file_path)
  {
    CAMLparam1(file_path);
    int ok;

    FILE *f = fopen(caml_strdup(String_val(file_path)), "rb");
    struct result item = pull_all_data(f);
    fclose(f);

    BrotliMemInput memin;
    BrotliInput in = BrotliInitMemInput(item.data, item.len, &memin);
    free(item.data);
    BrotliOutput out;
    std::vector<uint8_t> output;

    out.cb_ = &output_callback;
    out.data_ = &output;

    ok = BrotliDecompress(in, out);
    std::string str(output.begin(), output.end());

    if (ok) {
      //This is incorrect.
      CAMLreturn(caml_copy_string(str.c_str()));
    } else {
      caml_failwith("Decompression error");
    }
  }
}
