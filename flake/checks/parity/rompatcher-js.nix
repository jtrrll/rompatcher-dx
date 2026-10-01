{ inputs, ... }:
{
  config.perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config.checks."parity:rompatcher-js" =
        pkgs.runCommandLocal "rompatcher-js-parity"
          {
            nativeBuildInputs = [ pkgs.python3 ];
            rompatcherDX = lib.getExe config.packages.rompatcher-dx;
            rompatcherJs =
              lib.getExe
                (pkgs.extend (import inputs.nix-lib { inherit lib; }).overlays.pkgs).rompatcher-js;
          }
          ''
            python3 ${./rompatcher-js.py}
            touch "$out"
          '';
    };
}
