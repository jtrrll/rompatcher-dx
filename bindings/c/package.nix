{
  cargoDeps,
  diplomat-tool,
  meta,
  rustPlatform,
  src,
  version,
}:
rustPlatform.buildRustPackage {
  pname = "rompatcher-dx-c";
  inherit cargoDeps src version;
  cargoBuildFlags = [
    "--package"
    "rompatcher-dx-ffi"
  ];
  doCheck = false;
  nativeBuildInputs = [ diplomat-tool ];

  postInstall = ''
    diplomat-tool --silent --entry crates/rompatcher-dx-ffi/src/lib.rs c "$out/include"
  '';

  meta = meta // {
    description = "C bindings to the rompatcher-dx library";
  };
}
