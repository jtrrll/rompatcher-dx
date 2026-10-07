# rompatcher-dx

A ROM patching library and CLI.

## Development

Enter the Nix development shell with `nix develop --impure`.
Build and test the Rust library and CLI with `cargo build` and `cargo test`, or build
the Nix package with `nix build .#rompatcher-dx`.

The Diplomat bridge in `crates/rompatcher-dx-ffi` exposes `apply_patches` and
`create_patch`. The C and JavaScript packages live in `bindings/c/` and `bindings/js/`.
Build them with `nix build .#rompatcher-dx.bindings.c` and
`nix build .#rompatcher-dx.bindings.js`.

The C package supplies generated headers and a native static library. The JavaScript
package supplies `package.json`, ESM and TypeScript files, and WASM under its `lib/`
directory for npm packaging.

Lean proofs about the Rust library's Aeneas translation live in `proofs/`. Build them
with `nix build .#rompatcher-dx.proofs`, or locally with `generate-lean-model` followed
by `lake build` in `proofs/`.

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
