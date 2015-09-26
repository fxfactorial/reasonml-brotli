This is super alpha OCaml bindings to the new compression library
release by Google called [brotli](https://github.com/google/brotli)

# Make this work!

Right now their repo doesn't even provide a build process, so to use
this library you need to:

1.  Go here <https://github.com/bagder/libbrotli> and follow the README's
    steps, make sure you do the `make install` step.
2.  Then `git clone` this repo and do

```shell
opam pin add brotli .
```

Now you will have OCaml bindings to the Decoder available and a
command line utility named `brozip`

# Issues

1.  Because libbrotli is only exposing the decoder as a library, that's
    I have I to link against, aka no compressing yet.
2.  I suck at `C++`
