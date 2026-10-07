{ inputs, ... }:
{
  config.perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      lakePackageOverrides = pkgs.writeText "package-overrides.json" (
        builtins.toJSON {
          schemaVersion = "1.2.0";
          packages = map (dependency: {
            type = "path";
            name = dependency.passthru.lakePackageName;
            inherited = false;
            dir = "${dependency}";
          }) config.packages.default.proofs.allLeanDeps;
        }
      );
    in
    {
      config.devenv = {
        modules = [
          ({ lib, ... }: {
            containers = lib.mkForce { }; # Workaround to remove containers from flake checks.
          })
        ];

        shells.default = {
          inputsFrom = [
            config.packages.default
            config.packages.default.bindings.js
            config.packages.default.proofs
          ];
          languages.nix.enable = true;
          packages = [
            inputs.aeneas.packages.${system}.aeneas
            pkgs.cargo
            pkgs.clippy
            pkgs.rustc
            pkgs.rustfmt
          ];

          enterShell = ''
            mkdir -p proofs/.lake
            install -m644 ${lakePackageOverrides} proofs/.lake/package-overrides.json
          '';

          scripts.generate-lean-model = {
            description = "Generates the Lean model of the Rust crate into proofs/generated/";
            exec = ''
              model=$(nix build --no-link --print-out-paths .#rompatcher-dx.proofs.leanModel)
              rm -rf proofs/generated
              cp -r "$model" proofs/generated
              chmod -R u+w proofs/generated
            '';
          };

          git-hooks = {
            default_stages = [ "pre-push" ];
            hooks = {
              actionlint.enable = true;
              check-added-large-files = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              check-json.enable = true;
              check-yaml.enable = true;
              detect-private-keys = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              end-of-file-fixer.enable = true;
              flake-checker.enable = true;
              fmt = {
                enable = true;
                entry = "nix fmt";
                name = "fmt";
              };
              mixed-line-endings.enable = true;
              nil.enable = true;
              no-commit-to-branch = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              ripsecrets.enable = true;
            };
          };
        };
      };
    };
}
