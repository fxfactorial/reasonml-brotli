These are OCaml bindings to the compression algorithm/code released by
Google called [Brotli](https://github.com/google/brotli).

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

I have only provided a way to use this from native code (So you can't
play with it in `utop`), you can use it in your programs like:

```shell
$ ocamlfind ocamlopt -package brotli -linkpkg f.ml -o program
```

The API is very simple and limited to compressing, decompressing byte
strings; type `make doc` in the source repo and you get pretty HTML
docs in the `doc` repo, just open `index.html`.

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
