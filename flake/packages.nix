{ inputs, ... }:
{
  config.perSystem =
    { pkgs, system, ... }:
    let
      package = pkgs.callPackage ../package.nix {
        inherit (inputs.aeneas.packages.${system}) aeneas;
        aeneasLeanLibrary = pkgs.callPackage ./aeneas/lean-library.nix { aeneasSource = inputs.aeneas; };
        diplomat-tool = pkgs.callPackage ./diplomat/tool.nix { };
        extractCrateWithCharon = inputs.aeneas.inputs.charon.extractCrateWithCharon.${system};
      };
    in
    {
      config.checks = {
        "bindings:c" = package.bindings.c;
        "bindings:js" = package.bindings.js;
        "package:build" = package;
        "package:prove" = package.proofs;
      };

      config.packages = {
        default = package;
        rompatcher-dx = package;
      };
    };
}
