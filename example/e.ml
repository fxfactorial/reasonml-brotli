
let raw_data =
    {|
<html>
  <div>
    Hello World World World World
  </div>
</html>
|}
let () =
  let compressed = Brotli.Compress.bytes raw_data in
  let compressed_len = Bytes.length compressed in
  Printf.sprintf
    "Compressed length %d, data:%s"
    compressed_len
    compressed
  |> print_endline;

  let decompressed = Brotli.Decompress.bytes compressed in
  let decompressed_len = Bytes.length decompressed in
  Printf.sprintf
    "Decompressed length %d, data:%s"
    decompressed_len
    decompressed
  |> print_endline
