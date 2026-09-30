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
    leanDeps = [ leanPackages.Cli ];
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

    meta = {
      description = "ROM patching library and CLI written in Lean 4";
      homepage = "https://github.com/jtrrll/rompatcher-dx";
      license = lib.licenses.agpl3Only;
      maintainers = [
        {
          name = "jtrrll";
          github = "jtrrll";
          githubId = 77407057;
        }
      ];
      mainProgram = "rompatcher-dx";
      outputsToInstall = [ "out" ];
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      sourceProvenance = [ lib.sourceTypes.fromSource ];
    };
  }
)
