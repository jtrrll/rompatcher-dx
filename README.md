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

## License

Licensed under the [GNU AGPL v3](LICENSE).
