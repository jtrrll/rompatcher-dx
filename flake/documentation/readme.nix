{
  config.perSystem = _: {
    config.files = {
      file."README.md".text = ''
        # rompatcher-dx

        A ROM patching library and CLI.

        ## Development

        Enter the Nix development shell with `nix develop --impure`.

        Regenerate repository files after changing their Nix definitions with
        `nix run --impure .#write-files`.

        ## License

        Licensed under the [GNU AGPL v3](LICENSE).
      '';
      writer.app = true;
    };
  };
}
