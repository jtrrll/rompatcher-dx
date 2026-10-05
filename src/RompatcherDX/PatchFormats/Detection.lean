/-!
# Patch-format detection

This module identifies patch formats by their file extensions and parses format names.
-/

namespace RompatcherDX.PatchFormats

/-- The patch formats supported by rompatcher-dx. -/
inductive PatchFormat where
  /-- The International Patching System format. -/
  | ips

/-- Parses a case-insensitive patch-format name. -/
def PatchFormat.parse? (name : String) : Option PatchFormat :=
  match name.toLower with
  | "ips" => some PatchFormat.ips
  | _ => none

/-- Identifies the format of a patch file by its case-insensitive file extension. -/
def PatchFormat.fromExtension? (path : System.FilePath) : Option PatchFormat :=
  let lowercaseExtension? := path.extension.map (fun extension => extension.toLower)
  match lowercaseExtension? with
  | some "ips" => some PatchFormat.ips
  | _ => none

end RompatcherDX.PatchFormats
