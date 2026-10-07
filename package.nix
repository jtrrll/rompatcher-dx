{
  aeneas,
  aeneasLeanLibrary,
  callPackage,
  diplomat-tool,
  extractCrateWithCharon,
  lib,
  leanPackages,
  runCommand,
  rustPlatform,
}:
let
  cargoManifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  lakefile = builtins.fromTOML (builtins.readFile ./proofs/lakefile.toml);
  meta = {
    homepage = "https://github.com/jtrrll/rompatcher-dx";
    license = lib.licenses.agpl3Only;
    maintainers = [
      {
        name = "jtrrll";
        github = "jtrrll";
        githubId = 77407057;
      }
    ];
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rompatcher-dx";
  inherit (cargoManifest.workspace.package) version;
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./crates
    ];
  };
  cargoLock.lockFile = ./Cargo.lock;
  cargoBuildFlags = [
    "--package"
    "rompatcher-dx-cli"
  ];

  passthru.bindings =
    let
      inherit (finalAttrs) src cargoDeps version;
      c = callPackage ./bindings/c/package.nix {
        inherit
          src
          cargoDeps
          version
          diplomat-tool
          meta
          ;
      };
    in
    {
      inherit c;
      js = callPackage ./bindings/js/package.nix {
        inherit
          src
          cargoDeps
          version
          diplomat-tool
          meta
          ;
      };
    };

  passthru.proofs =
    let
      # Error messages are not part of the model, so their trait implementations are left out.
      untranslatedItems = [
        "{impl core::fmt::Display for rompatcher_dx::Error}"
        "{impl core::fmt::Display for rompatcher_dx::formats::ips::codec::Error}"
        "{impl core::error::Error for rompatcher_dx::Error}"
        "{impl core::error::Error for rompatcher_dx::formats::ips::codec::Error}"
      ];

      llbc = extractCrateWithCharon {
        name = finalAttrs.pname;
        inherit (finalAttrs) src;
        charonArgs = lib.escapeShellArgs (
          [ "--preset=aeneas" ]
          ++ lib.concatMap (item: [
            "--exclude"
            item
          ]) untranslatedItems
        );
        cargoArgs = "--package rompatcher-dx";
      };

      # Aeneas names the generated Lean module after the LLBC file.
      leanModel = runCommand "${finalAttrs.pname}-lean-model" { nativeBuildInputs = [ aeneas ]; } ''
        cp ${llbc} RompatcherDX.llbc
        aeneas -backend lean -abort-on-error -no-progress-bar \
          -namespace RompatcherDX -dest "$out" RompatcherDX.llbc
      '';
    in
    leanPackages.buildLakePackage {
      pname = "${lakefile.name}-proofs";
      inherit (lakefile) version;
      leanPackageName = lakefile.name;
      leanDeps = [ aeneasLeanLibrary ];
      src = lib.fileset.toSource {
        root = ./proofs;
        fileset = lib.fileset.unions [
          ./proofs/lakefile.toml
          ./proofs/lake-manifest.json
          ./proofs/lean-toolchain
          ./proofs/src
        ];
      };

      postPatch = ''
        cp -r ${leanModel} generated
      '';

      passthru = { inherit leanModel; };

      meta = meta // {
        description = "Proofs about the Aeneas translation of the rompatcher-dx library";
      };
    };

  meta = meta // {
    description = "ROM patching library and CLI";
    mainProgram = "rompatcher-dx";
  };
})
