(** OCaml bindings to the Brotli compression library, uses Bigarrays
    for performance *)

module Decompress : sig

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

  type mode =
    | Generic (** Compression is not aware of any special features of input *)
    | Text (** Compression knows that input is UTF-8 *)
    | Font (** Compression knows that input is WOFF 2.0 *)

  (** Compress a file given at file_src and write the compressed file
      to file_dst *)
  val to_path :
    file_src:string -> file_dst:string -> unit Lwt.t

  (** Compress a file and give back in memory the compressed contents
      as a Bigarray *)
  val to_mem:
    string ->
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t

  (** Compress the given bytes string to a compressed bytes string *)
  val to_bytes:
    ?mode:mode -> ?quality:int -> ?lgwin:int -> ?lgblock:int -> bytes -> bytes Lwt.t

end
