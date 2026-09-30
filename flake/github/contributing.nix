{
  config.perSystem = _: {
    config.files.file.".github/CONTRIBUTING.md".text = ''
      # Contributing

      When contributing to this repository, consider opening an issue first to
      discuss substantial changes.

      We have a code of conduct, please follow it in all your interactions with the project.

      ## Pull Request Process

      1. Check your changes locally with `nix flake check --impure`.
      2. Open a pull request with a descriptive, succinct title and explain what changed.
    '';
  };
}
