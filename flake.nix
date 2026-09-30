{
  description = "A ROM patching library and CLI";

  inputs = {
    devenv.url = "github:cachix/devenv/main";
    files = {
      flake = false;
      url = "github:mightyiam/files/master";
    };
    flake-parts.url = "github:hercules-ci/flake-parts/main";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix/main";
    treefmt-nix = {
      flake = false;
      url = "github:numtide/treefmt-nix/main";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        (inputs.files + "/flake-module.nix")
        inputs.terranix.flakeModule
        (inputs.treefmt-nix + "/flake-module.nix")
        ./flake/devshell.nix
        ./flake/formatting.nix
        ./flake/documentation/license.nix
        ./flake/documentation/readme.nix
        ./flake/github/ci.nix
        ./flake/github/code_of_conduct.nix
        ./flake/github/codeowners.nix
        ./flake/github/contributing.nix
        ./flake/github/dependabot.nix
        ./flake/github/issues.nix
        ./flake/github/pull_request_template.nix
        ./flake/github/repository.nix
        ./flake/packages.nix
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
}
