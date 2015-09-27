(** Raw call to decompress the big array to the given target file path *)
external unpack_data_raw :
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t -> string -> unit = "brotli_ml_decompress_paths"

(** Decompresses a file at filepath *)
let decompress ?file_dest file_src =
  let open Lwt in
  match file_dest with
  (* Come back to this *)
  | Some p -> return ()
  | None ->
    let open Lwt_unix in
    stat file_src >>= fun size ->
    openfile file_src [O_RDONLY] 0o666 >>= fun fd ->
    let this_bigarray =
      let open Bigarray in
      Bigarray.Array1.map_file (unix_file_descr fd) Char C_layout false size.st_size
    in
    unpack_data_raw this_bigarray (Filename.chop_extension file_src);
    close fd
