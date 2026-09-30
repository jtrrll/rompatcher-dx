{
  config.perSystem = _: {
    config.devenv.shells.default = {
      languages = {
        lean4.enable = true;
        nix.enable = true;
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
}
