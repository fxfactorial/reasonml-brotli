These are alpha quality OCaml bindings to the new compression library
released by Google called [brotli](https://github.com/google/brotli).

# Installation

I assume that you have [opam](https://opam.ocaml.org) installed, it is OCaml's package manager.

All you have to do is:

```shell
$ opam pin add brotli .
```

and you'll have the `Brotli` module to use and the executable `brozip`

# brozip usage

Right now its quite simple, but since its built with `cmdliner`,
there's a nice man page, see it with `brozip --help` 
Basically if you do 

```shell
$ brozip fileone.compressed filetwo.compressed
```

then you'll get uncompressed files named `fileone`, `filetwo`

# Issues

1.  Because libbrotli is only exposing the decoder as a library, that's
    I have I to link against, aka no compressing yet.
2.  I suck at `C++`
