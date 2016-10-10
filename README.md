These are OCaml bindings to the compression algorithm/code released by
Google called [Brotli](https://github.com/google/brotli).

# Dependencies
Make sure you have [libbrotli](https://github.com/bagder/libbrotli)
installed, otherwise this installation will fail. There's a helper
script in this repo that will do it for you, `bash prepare.sh`.

# Installation

I assume that you have [opam](https://opam.ocaml.org) installed, it is
OCaml's package manager.

```shell
$ opam install brotli
```

if wanting to install locally, then I recommend using an `opam pin`,
assuming you're in the root of the directory, do: 

```shell
$ opam pin add brotli . -y
```

Compile with:

```shell
$ ocamlfind ocamlopt -package brotli -linkpkg f.ml -o program
```

Or play with it directly in `utop`:

![](./compressed_image.png)

The API is very simple and limited to compressing, decompressing byte
strings; type `make doc` in the source repo and you get pretty HTML
docs in the `doc` repo, just open `index.html`.

# API 

This is directly the commented `mli`, you can control compression
settings and I've exposed the ability to add a custom dictionary.

```ocaml
(** OCaml bindings to the Brotli compression library *)

(** Provides functions for decompressing Brotli algorithm compressed
    files, functions may raise the Decompression_failure exception *)
module Decompress : sig

  (** Decompress compressed byte string *)
  val bytes : ?custom_dictionary:bytes -> bytes -> bytes

  (** Brotli decoder version *)
  val version : string
end

(** Provides functions for compression using the Brotli algorithm with
    adjustable parameters, defaults are what Google uses. Be aware
    that compression may raise the Compression_failure exception *)
module Compress : sig

  (** Brotli encoder version *)
  val version : string

  type mode =
    | Generic (** Compression is not aware of any special features of input *)
    | Text    (** Compression knows that input is UTF-8 *)
    | Font    (** Compression knows that input is WOFF 2.0 *)

  (** Controls the compression-speed vs compression-density
      tradeoffs. The higher the quality, the slower the
      compression. Range is `_0 to `_11. *)
  type quality = [`_0 | `_1 | `_2 | `_3 | `_4 | `_5 |
                  `_6 | `_7 | `_8 | `_9 | `_10 | `_11]

  (** Base 2 logarithm of the sliding window size. Range is `_10 to
      `_24. *)
  type lgwin = [`_10 | `_11 | `_12 | `_13 | `_14
               | `_15 | `_16 | `_17 | `_18 | `_19
               | `_20 | `_21 | `_22 | `_23 | `_24]

  (** Base 2 logarithm of the maximum input block size. Range is `_16 to
      `_24. If set to `_0, the value will be set based on the quality. *)
  type lgblock = [`_0 | `_16 | `_17 | `_18 | `_19
                 | `_20 | `_21 | `_22 | `_23 | `_24]

  (** Compress the given bytes string to a compressed bytes string *)
  val bytes:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    ?custom_dictionary:bytes ->
    bytes -> bytes

end
```

Here's an example usage:

```ocaml
let () =
  let raw_data =
    {|
<html>
  <div>
    Hello World World World World
  </div>
</html>
|}
  in
  Printf.sprintf
    "Encoder version %s, Decoder version %s"
    Brotli.Compress.version
    Brotli.Decompress.version
  |> print_endline;

  let compressed = Brotli.Compress.bytes raw_data in
  let compressed_len = Bytes.length compressed in
  Printf.sprintf
    "Compressed length %d" compressed_len |> print_endline;

  let decompressed = Brotli.Decompress.bytes compressed in
  let decompressed_len = Bytes.length decompressed in
  Printf.sprintf
    "Decompressed length %d, data:%s"
    decompressed_len
    decompressed
  |> print_endline;

  if String.compare raw_data decompressed = 0
  then print_endline "Data was correct in roundtrip"
  else failwith "Data was not equal during roundtrip"
```
