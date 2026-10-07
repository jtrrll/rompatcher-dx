{
  config.perSystem =
    { pkgs, ... }:
    let
      vendoredCrates = pkgs.rustPlatform.importCargoLock { lockFile = ../Cargo.lock; };

      # Cargo reads source replacement only from config files, and `cargo clippy` does not pass
      # `--config` on to the `cargo check` it runs.
      cargoConfig = pkgs.writeText "config.toml" ''
        [source.crates-io]
        replace-with = "vendored-sources"

        [source.vendored-sources]
        directory = "${vendoredCrates}"
      '';

      # Clippy lints whole crates, so the file paths passed by treefmt are ignored.
      clippy = pkgs.writeShellApplication {
        name = "clippy";
        runtimeInputs = [
          pkgs.cargo
          pkgs.clippy
          pkgs.rustc
          pkgs.stdenv.cc
        ];
        text = ''
          CARGO_HOME=$(mktemp -d)
          export CARGO_HOME
          trap 'rm -rf "$CARGO_HOME"' EXIT
          cp ${cargoConfig} "$CARGO_HOME/config.toml"
          cargo clippy --offline --workspace --all-targets --quiet
        '';
      };
    in
    {
      config.treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          deadnix.enable = true;
          gofmt.enable = true;
          keep-sorted.enable = true;
          nixfmt.enable = true;
          rustfmt.enable = true;
          statix.enable = true;
        };
        settings.formatter.clippy = {
          command = pkgs.lib.getExe clippy;
          includes = [ "*.rs" ];
          priority = 1;
        };
      };
    };
}
