module C = Configurator.V1

let libs = [ "brotlidec"; "brotlienc" ]

let default : C.Pkg_config.package_conf =
  {
    libs = "-L/usr/local/lib" :: List.map (fun lib -> "-l" ^ lib) libs;
    cflags = [ "-I/usr/local/include" ];
  }

let merge_conf ({ libs; cflags } : C.Pkg_config.package_conf)
    ({ libs = libs'; cflags = cflags' } : C.Pkg_config.package_conf) :
    C.Pkg_config.package_conf =
  {
    libs = List.concat [ libs; libs' ];
    cflags = List.concat [ cflags; cflags' ];
  }

let empty_conf : C.Pkg_config.package_conf = { libs = []; cflags = [] }

let () =
  C.main ~name:"brotli" (fun c ->
      let conf =
        Option.value ~default
        @@ List.fold_left
             (fun conf lib ->
               Option.bind conf @@ fun conf ->
               Option.bind (C.Pkg_config.get c) @@ fun pc ->
               Option.bind (C.Pkg_config.query pc ~package:("lib" ^ lib))
               @@ fun deps -> Some (merge_conf conf deps))
             (Some empty_conf) libs
      in

      C.Flags.write_sexp "c_flags.sexp" conf.cflags;
      C.Flags.write_sexp "c_library_flags.sexp" conf.libs)
