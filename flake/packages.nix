{
  config.perSystem =
    { pkgs, ... }:
    let
      package = pkgs.callPackage ../package.nix { };
    in
    {
      config.checks."packages:rompatcher-dx/build" = package;

      config.packages = {
        default = package;
        rompatcher-dx = package;
      };
    };
}
