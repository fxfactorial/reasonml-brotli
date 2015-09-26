(* I probably need to use big array *)
let () =
  (* open_in_bin Sys.argv.(1) |> IO.input_channel |> IO.read_all *)
  (* |> Brotli.decompress_buffer *)
  (* |> print_endline *)
  Sys.argv.(1)
  |> Brotli.decompress_buffer
  |> print_endline
