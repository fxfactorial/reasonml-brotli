(** OCaml bindings to the Brotli compression library, uses Bigarrays
    for performance *)

module Decompress : sig

  (** Decompresses a file given at file_src and store at destination,
      if no destination given then store at given file origin name
      just without an extension of the original file
      name. i.e. foo.compressed becomes foo *)
  val decompress_to_path : ?file_dst:string -> file_src:string -> unit Lwt.t

  (** Decompress a file at filepath and give back in memory the
      decompressed contents as a Bigarray *)
  val decompress_to_mem :
    string ->
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t

end

module Compress : sig

  (** Compress a file given at file_src and write the compressed file
      to file_dst *)
  val compress_to_path : file_src:string -> file_dst:string -> unit Lwt.t

  val compress_to_mem:
    string ->
    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t Lwt.t

end
