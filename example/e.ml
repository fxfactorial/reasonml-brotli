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
  Printf.sprintf
    "Encoder version %s, Decoder version %s"
    Brotli.Compress.version
    Brotli.Decompress.version
  |> print_endline;

  let compressed = Brotli.Compress.bytes raw_data in
  let compressed_len = Bytes.length compressed in
  Printf.sprintf
    "Compressed length %d" compressed_len |> print_endline;

  let decompressed =
    Brotli.Decompress.bytes
      ~on_part_decompressed:(fun piece ->
          Printf.sprintf "Finished %d" (Nativeint.to_int piece) |> print_endline
        )
      compressed
  in
  let decompressed_len = Bytes.length decompressed in
  Printf.sprintf
    "Decompressed length %d, data:%s"
    decompressed_len
    decompressed
  |> print_endline;

  if String.compare raw_data decompressed = 0
  then print_endline "Data was correct in roundtrip"
  else failwith "Data was not equal during roundtrip"
