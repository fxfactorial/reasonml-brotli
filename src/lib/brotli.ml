open Lwt

(** Raw call to decompress the big array to the given target file
    path *)
external unpack_data_to_path :
  string ->
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t ->
  unit
  = "brotli_ml_decompress_path"

(** Decompress a Brotli compressed Bigarray and get back a
    decompressed Bigarray *)
external unpack_data_to_bigarray :
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t ->
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t
  = "brotli_ml_decompress_in_mem"

external pack_data_to_path :
  string ->
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t ->
  unit
  = "brotli_ml_compress_path"

external pack_data_to_bigarray :
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t ->
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t
  = "brotli_ml_compress_in_mem"

let barray_of_path file_src =
  let open Lwt_unix in
  stat file_src >>= fun size ->
  openfile file_src [O_RDONLY] 0o666 >>= fun fd ->
  let this_bigarray =
    let open Bigarray in
    Array1.map_file (unix_file_descr fd) Char C_layout false size.st_size
  in
  close fd >|= fun () ->
  this_bigarray

module Decompress = struct

  let to_path ?file_dst ~file_src =
    let do_inflate p = barray_of_path file_src >|= unpack_data_to_path p in
    match file_dst with
    | Some p -> do_inflate p
    | None -> do_inflate (Filename.chop_extension file_src)

  let to_mem file_src =
    barray_of_path file_src >|= unpack_data_to_bigarray

end

module Compress = struct

  type mode =
    | Generic (** Compression is not aware of any special features of input *)
    | Text (** Compression knows that input is UTF-8 *)
    | Font (** Compression knows that input is WOFF 2.0 *)

  let to_mem file_src =
    barray_of_path file_src >|= pack_data_to_bigarray

  let to_path ~file_src ~file_dst =
    barray_of_path file_src >|= (pack_data_to_path file_dst)

  external raw_to_bytes : bytes -> bytes = "brotli_ml_compress_to_bytes"

  let to_bytes ?(mode=Generic) ?(quality=11) ?(lgwin=22) ?(lgblock=0) s =
    raw_to_bytes s |> return

end
