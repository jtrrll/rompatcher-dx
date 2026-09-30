{
  config.perSystem = _: {
    config.treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        deadnix.enable = true;
        keep-sorted.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
      };
    };
  };
}
