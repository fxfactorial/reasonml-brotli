(** OCaml bindings to the Brotli compression library, uses Bigarrays
    for performance *)

(** Create a bytes string from a Bigarray *)
val barray_to_bytes : (char, 'a, 'b) Bigarray.Array1.t -> bytes

(** Create a Bigarray out from a bytes string *)
val bytes_to_barray : bytes ->
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

module Decompress : sig

  (** Raised when there was a failure in decompressing the data *)
  type exn += Decompression_failure of string

  (** Decompresses a file given at file_src and store at destination,
      if no destination given then store at given file origin name
      just without an extension of the original file
      name. i.e. foo.compressed becomes foo *)
  val to_path : ?file_dst:string -> file_src:string -> unit Lwt.t

  (** Decompress a file at filepath and give back in memory the
      decompressed contents as a Bigarray *)
  val to_mem :
    string ->
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t

end

module Compress : sig

  (** Raised when compression could not occur *)
  type exn += Compression_failure of string

  (** Raised when one of the compression parameters is not in an
      appropriate range *)
  type exn += Compression_param_invalid of string

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
      to file_dst *)
  val to_path :
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    file_src:string ->
    file_dst:string ->
    unit Lwt.t

  (** Compress a file and give back in memory the compressed contents
      as a Bigarray *)
  val to_mem:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    string ->
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t

  (** Compress the given bytes string to a compressed bytes string *)
  val to_bytes:
    ?mode:mode ->
    ?quality:quality ->
    ?lgwin:lgwin ->
    ?lgblock:lgblock ->
    bytes ->
    bytes Lwt.t

end
