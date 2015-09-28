These are OCaml bindings to the new compression library released by
Google called [brotli](https://github.com/google/brotli) along with a command line tool called `brozip`

# Installation

I assume that you have [opam](https://opam.ocaml.org) installed, it is OCaml's package manager.

All you have to do, until I get this up on `opam` is:

```shell
$ opam pin add brotli .
```

and you'll have the `Brotli` module to use and the executable `brozip`
which can decompress, compress files concurrently

# brozip usage

Right now its quite simple but still concurrent, but since its built
with `cmdliner`, there's a nice man page, see it with `brozip --help`
Basically if you do

```shell
$ brozip fileone.compressed filetwo.compressed
```

then you'll get uncompressed files named `fileone`, `filetwo`

# Issues

1.  I suck at `C++` so its maybe not the most idiomatic but it works.
2.  Some low hanging fruit available for refactoring, leaving it for a
    pull request for a developer eager to get into open-source.
