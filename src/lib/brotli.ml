open Lwt

external unpack_data_to_path :
  string ->
  ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t ->
  unit
  = "brotli_ml_decompress_path"

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

let barray_to_bytes barray =
  let b_size = Bigarray.Array1.dim barray in
  (* Any way to do this without having to make this string? *)
  let as_bytes = Bytes.create b_size in
  for i = 0 to b_size - 1 do
    Bytes.set as_bytes i (Bigarray.Array1.unsafe_get barray i)
  done;
  as_bytes

let bytes_to_barray bytes =
  let open Bigarray in
  let b_array = Array1.create Char C_layout (String.length bytes) in
  for i = 0 to String.length bytes - 1 do
    Array1.unsafe_set b_array i bytes.[i]
  done;
  b_array

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
    | Text    (** Compression knows that input is UTF-8 *)
    | Font    (** Compression knows that input is WOFF 2.0 *)

  let to_mem file_src =
    barray_of_path file_src >|= pack_data_to_bigarray

  let to_path ~file_src ~file_dst =
    barray_of_path file_src >|= (pack_data_to_path file_dst)

  let to_bytes ?(mode=Generic) ?(quality=11) ?(lgwin=22) ?(lgblock=0) s =
    (* Turn the bytes string into bigarray, then compress big array
       into memory, turn big array back into bytes string *)
    bytes_to_barray s |> pack_data_to_bigarray |> barray_to_bytes |> return

end
