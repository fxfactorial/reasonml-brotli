
let exhaust ic =
  let all_input = ref [] in
  try
    while true do
      all_input := input_line ic :: !all_input;
    done;
    []
  with
    End_of_file ->
    close_in ic;
    List.rev !all_input

let read_all path =
  open_in path |> exhaust |> String.concat ""

let () =
  Brotli.decompress_buffer (read_all Sys.argv.(1)) |> print_endline
