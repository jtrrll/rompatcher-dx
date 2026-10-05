{
  config.perSystem = _: {
    config.files = {
      file."README.md".text = ''
        # rompatcher-dx

        A ROM patching library and CLI.

        ## Development

        Enter the Nix development shell with `nix develop --impure`.
        Build the Lean library and executable with `lake build`, or build the Nix
        package with `nix build .#rompatcher-dx`.
        The CLI is in the default Nix output; build the Lean library output with
        `nix build .#rompatcher-dx.lib`.

        Regenerate repository files after changing their Nix definitions with
        `nix run --impure .#write-files`.


        ## TODO

        Before 1.0.0 release:
        - [x] Implement IPS support
        - [ ] Prove IPS correctness
        - [ ] Implement UPS support
        - [ ] Prove UPS correctness
        - [ ] Implement BPS support
        - [ ] Prove BPS correctness
        - [ ] Expose C bindings
        - [ ] Expose Rust bindings
        - [ ] Expose JS/TS bindings (WASM?)

        ## License

        Licensed under the [GNU AGPL v3](LICENSE).
      '';
      writer.app = true;
    };
  };
}
