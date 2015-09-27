(** Raw call to decompress the big array to the given target file path *)
external unpack_data_to_path :
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t -> string -> unit = "brotli_ml_decompress_paths"


(** Decompresses a file at filepath *)
let decompress ?file_dest file_src =
  let do_inflate p =
    let open Lwt_unix in
    let open Lwt in
    stat file_src >>= fun size ->
    openfile file_src [O_RDONLY] 0o666 >>= fun fd ->
    let this_bigarray =
      let open Bigarray in
      Bigarray.Array1.map_file (unix_file_descr fd) Char C_layout false size.st_size
    in
    unpack_data_to_path this_bigarray p;
    close fd
  in
  match file_dest with
  | Some p -> do_inflate p
  | None -> do_inflate (Filename.chop_extension file_src)
