(** OCaml bindings to the Brotli compression library, uses Bigarrays
    for performance *)

(** Alias for the Bigarray layout of compression input/output *)
type data =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

(** Create a bytes string from a Bigarray *)
val to_bytes : data -> bytes

(** Create a Bigarray out from a bytes string *)
val to_bigarray : bytes -> data

(** Provides functions for decompressing Brotli algorithm compressed
    files, functions may raise the Decompression_failure exception *)
module Decompress : sig

  (** Raised when there was a failure in decompressing the data, read
      the message provided. *)
  type exn += Decompression_failure of string

  (** Decompresses a file given path and store at destination, if no
      destination given then store at given file origin name just
      without an extension of the original file
      name. i.e. foo.compressed becomes foo *)
  (* val to_path : ?file_dst:bytes -> bytes -> unit Lwt.t *)

  (** Decompress a file at filepath and give back in memory the
      decompressed contents as a Bigarray *)
  (* val to_mem : *)
  (*   bytes -> *)
  (*   (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t *)

  (** Decompress compressed bytes string *)
  val to_bytes : ?custom_dictionary:data -> bytes -> bytes

end

(** Provides functions for compression using the Brotli algorithm with
    adjustable parameters, defaults are what Google uses. Be aware
    that compression may raise the Compression_failure exception *)
module Compress : sig

  (** Raised when compression could not occur *)
  type exn += Compression_failure of string

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

  (** Compress a file given at file_src and write the compressed file
      to second argument path *)
  (* val to_path : *)
  (*   ?mode:mode -> *)
  (*   ?quality:quality -> *)
  (*   ?lgwin:lgwin -> *)
  (*   ?lgblock:lgblock -> *)
  (*   file_src:string -> *)
  (*   string -> unit *)

  val of_bytes:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    ?custom_dictionary:data ->
    bytes
    -> data

  (** Compress a file and give back in memory the compressed contents
      as a Bigarray *)
  val of_file:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    ?custom_dictionary:data ->
    string ->
    data

  (** Compress the given bytes string to a compressed bytes string *)
  val to_bytes:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    ?custom_dictionary:data ->
    bytes -> bytes

end
