{
  aeneasSource,
  leanPackages,
}:
leanPackages.buildLakePackage {
  pname = "aeneas";
  version = "0-unstable";
  src = aeneasSource + "/backends/lean";
  leanDeps = [ leanPackages.mathlib ];

  # Precompiled modules would make dependent builds write shared libraries into the read-only store.
  postPatch = ''
    substituteInPlace lakefile.lean \
      --replace-fail "precompileModules := notCI" "precompileModules := false"
  '';
}
