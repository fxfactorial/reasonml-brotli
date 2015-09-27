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

let decompress_to_path ?file_dest file_src =
  let do_inflate p = barray_of_path file_src >|= unpack_data_to_path p in
  match file_dest with
  | Some p -> do_inflate p
  | None -> do_inflate (Filename.chop_extension file_src)

let decompress_to_mem file_src =
  barray_of_path file_src >|= unpack_data_to_bigarray
