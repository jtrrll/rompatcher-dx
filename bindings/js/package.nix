{
  cargo,
  cargoDeps,
  diplomat-tool,
  lld,
  meta,
  rustc,
  rustPlatform,
  src,
  stdenv,
  version,
}:
stdenv.mkDerivation {
  pname = "rompatcher-dx-js";
  inherit cargoDeps src version;
  nativeBuildInputs = [
    cargo
    diplomat-tool
    lld
    rustc
    rustPlatform.cargoSetupHook
  ];

  buildPhase = ''
    runHook preBuild
    cargo build --release --offline --package rompatcher-dx-ffi --target wasm32-unknown-unknown
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    diplomat-tool --silent --entry crates/rompatcher-dx-ffi/src/lib.rs js "$out/lib/api"
    install -Dm644 target/wasm32-unknown-unknown/release/rompatcher_dx_ffi.wasm \
      "$out/lib/api/rompatcher_dx_ffi.wasm"
    install -Dm644 ${./diplomat.config.mjs} "$out/lib/diplomat.config.mjs"
    install -Dm644 ${./package.json} "$out/lib/package.json"
    runHook postInstall
  '';

  meta = meta // {
    description = "JavaScript bindings to the rompatcher-dx library";
  };
}
