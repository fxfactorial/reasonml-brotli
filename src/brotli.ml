
type data =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type mode = Generic | Text | Font

type params = {mode : int; quality : int; lgwin : int; lgblock : int }

type quality = [`_0 | `_1 | `_2 | `_3 | `_4 | `_5 |
                `_6 | `_7 | `_8 | `_9 | `_10 | `_11]

type lgwin = [`_10 | `_11 | `_12 | `_13 | `_14
             | `_15 | `_16 | `_17 | `_18 | `_19
             | `_20 | `_21 | `_22 | `_23 | `_24]

type lgblock = [`_0 | `_16 | `_17 | `_18 | `_19
               | `_20 | `_21 | `_22 | `_23 | `_24]

(* external unpack_data_to_path : *)
(*   string -> *)
(*   ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t -> *)
(*   unit *)
(*   = "brotli_ml_decompress_path" *)

external unpack_data_to_bigarray :
  data option -> data -> data = "brotli_ml_decompress_in_mem"

(* external pack_data_to_path : *)
(*   string -> *)
(*   params -> *)
(*   ('char, 'int8_unsigned_elt, 'layout) Bigarray.Array1.t -> *)
(*   unit *)
(*   = "brotli_ml_compress_path" *)

external pack_data_to_bigarray :
  data option -> params -> data -> data = "brotli_ml_compress_in_mem"

let to_bytes barray = Bigarray.(
    let b_size = Array1.dim barray in
    (* Any way to do this without having to make this string? *)
    let as_bytes = Bytes.create b_size in
    for i = 0 to b_size - 1 do Bytes.set as_bytes i (Array1.unsafe_get barray i)
    done;
    as_bytes
  )

let to_bigarray bytes = Bigarray.(
    let b_array = Array1.create Char C_layout (Bytes.length bytes) in
    for i = 0 to Bytes.length bytes - 1 do Array1.unsafe_set b_array i bytes.[i]
    done;
    b_array
  )

let bigarray_of_path file_src = Unix.(
    stat file_src |> fun stats ->
    openfile file_src [O_RDONLY] 0o666 |> fun fd ->
    let this_bigarray =
      let open Bigarray in
      Array1.map_file fd Char C_layout false stats.st_size
    in
    close fd;
    this_bigarray
  )

  (* let open Lwt_unix in *)
  (* stat file_src >>= fun size -> *)
  (* openfile file_src [O_RDONLY] 0o666 >>= fun fd -> *)
  (* let this_bigarray = *)
  (*   let open Bigarray in *)
  (*   Array1.map_file (unix_file_descr fd) Char C_layout false size.st_size *)
  (* in *)
  (* close fd >|= fun () -> *)
  (* this_bigarray *)

module Decompress = struct

  type exn += Decompression_failure of string

  (* let try_it = function *)
  (*   | t -> try%lwt t with Failure s -> raise (Decompression_failure s) *)

  (* let to_path ?file_dst file_src = *)
  (*   bigarray_of_path file_src *)
  (*   |> unpack_data_to_path *)
  (*     (match file_dst with *)
  (*      | Some p -> p *)
  (*      | None -> (Filename.chop_extension file_src)) *)


  let to_mem file_src = ()
    (* barray_of_path file_src >|= unpack_data_to_bigarray |> try_it *)

  let to_bytes ?custom_dictionary s =
    to_bigarray s |> unpack_data_to_bigarray custom_dictionary |> to_bytes

end

module Compress = struct

  type mode =
    | Generic
    | Text
    | Font

  type exn += Compression_failure of string

  type quality = [`_0 | `_1 | `_2 | `_3 | `_4 | `_5 |
                  `_6 | `_7 | `_8 | `_9 | `_10 | `_11]

  type lgwin = [`_10 | `_11 | `_12 | `_13 | `_14
               | `_15 | `_16 | `_17 | `_18 | `_19
               | `_20 | `_21 | `_22 | `_23 | `_24]

  type lgblock = [`_0 | `_16 | `_17 | `_18 | `_19
                 | `_20 | `_21 | `_22 | `_23 | `_24]

  let int_of_mode = function
    | Generic -> 0
    | Text -> 1
    | Font -> 2

  let int_of_quality (x : quality) = match x with
    | `_0 -> 0 | `_1 -> 1 | `_2 -> 2 | `_3 -> 3 | `_4 -> 4 | `_5 -> 5
    | `_6 -> 6 | `_7 -> 7 | `_8 -> 8 | `_9 -> 9 | `_10 -> 10 | `_11 -> 11

  let int_of_lgwin (x : lgwin) = match x with
    | `_10 -> 10 | `_11 -> 11 | `_12 -> 12 | `_13 -> 13 | `_14 -> 14
    | `_15 -> 15 | `_16 -> 16 | `_17 -> 17 | `_18 -> 18 | `_19 -> 19
    | `_20 -> 20 | `_21 -> 21 | `_22 -> 22 | `_23 -> 23 | `_24 -> 24

  let int_of_lgblock (x : lgblock) = match x with
    | `_0 | `_16 -> 16 | `_17 -> 17 | `_18 -> 18 | `_19 -> 19
    | `_20 -> 20 | `_21 -> 21 | `_22 -> 22 | `_23 -> 23 | `_24 -> 24

  let make_params m q lgw lgb =
    { mode = int_of_mode m;
      quality = int_of_quality q;
      lgwin = int_of_lgwin lgw;
      lgblock = int_of_lgblock lgb; }

  (* let try_it = function *)
  (*   | t -> try%lwt t with | Failure s -> raise (Compression_failure s) *)

  let of_bytes
      ?(mode=Generic)
      ?(quality : quality = `_11)
      ?(lgwin : lgwin = `_22)
      ?(lgblock : lgblock = `_0)
      ?custom_dictionary
      byte_string =
    pack_data_to_bigarray
      custom_dictionary
      (make_params mode quality lgwin lgblock)
      (to_bigarray byte_string)

  let of_file
      ?(mode=Generic)
      ?(quality : quality = `_11)
      ?(lgwin : lgwin = `_22)
      ?(lgblock : lgblock = `_0)
      ?custom_dictionary
      file_src =
    pack_data_to_bigarray
      custom_dictionary
      (make_params mode quality lgwin lgblock)
      (bigarray_of_path file_src)

  (* let to_path *)
  (*     ?(mode=Generic) *)
  (*     ?(quality : quality = `_11) *)
  (*     ?(lgwin : lgwin = `_22) *)
  (*     ?(lgblock : lgblock = `_0) *)
  (*     ~file_src *)
  (*     file_dst = *)
  (*   bigarray_of_path file_src *)
  (*   |> (pack_data_to_path file_dst (make_params mode quality lgwin lgblock)) *)

  let to_bytes
      ?(mode=Generic)
      ?(quality : quality = `_11)
      ?(lgwin : lgwin = `_22)
      ?(lgblock : lgblock = `_0)
      ?custom_dictionary
      s =
    to_bigarray s
    |> pack_data_to_bigarray custom_dictionary (make_params mode quality lgwin lgblock)
    |> to_bytes

end
