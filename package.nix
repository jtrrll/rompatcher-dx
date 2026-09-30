{
  lib,
  leanPackages,
}:
leanPackages.buildLakePackage (
  finalAttrs:
  let
    lakefile = builtins.fromTOML (builtins.readFile (finalAttrs.src + "/lakefile.toml"));
  in
  {
    pname = lakefile.name;
    inherit (lakefile) version;
    outputs = [
      "out"
      "lib"
    ];
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./src
        ./lakefile.toml
        ./lake-manifest.json
        ./lean-toolchain
      ];
    };

    postInstall = ''
      mv "$out" "$lib"
      install -Dm755 "$lib/.lake/build/bin/rompatcher-dx" "$out/bin/rompatcher-dx"
    '';
  }
)
