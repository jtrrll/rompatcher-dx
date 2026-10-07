{
  fetchCrate,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "diplomat-tool";
  version = "0.16.1";
  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-+x1uEhnVq/47lTycPtHqE4T0z2dLCpQUWXFdzyLoZQY=";
  };
  cargoHash = "sha256-gdyerVP3mq99MyCe+h4WrCola/xhun/o9K+CCshrVPo=";

  meta = {
    description = "Generates bindings to Rust libraries from Diplomat bridge modules";
    homepage = "https://github.com/rust-diplomat/diplomat";
    license = [
      lib.licenses.asl20
      lib.licenses.mit
    ];
    mainProgram = "diplomat-tool";
  };
})
