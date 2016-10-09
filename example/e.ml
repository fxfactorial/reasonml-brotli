

let () =
  let raw_data =
    {|
<html>
  <div>
    Hello World World World World
  </div>
</html>
|}
  in
  let compressed = Brotli.Compress.of_bytes raw_data in
  let len = Brotli.to_bytes compressed |> Bytes.length in
  Printf.sprintf
    "Org data len:%d, compressed length: %d" (Bytes.length raw_data) len
  |> print_endline;
  Printf.sprintf "Raw Output:%s" (Brotli.to_bytes compressed)
  |> print_endline;

  Brotli.Decompress.to_bytes (Brotli.to_bytes compressed)
  |> print_endline
