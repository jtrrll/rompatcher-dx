import RompatcherDX.TypeAliases
import RompatcherDX.PatchFormats.IPS

/-!
# Patch-format detection

This module identifies patch formats by their file headers and parses format names.
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

/-- Associates each known patch header with its format. -/
private def formatsByHeader : List (ByteArray × PatchFormat) :=
  [(IPS.header, PatchFormat.ips)]

/-- Identifies the format of a patch by matching the beginning of its bytes to a known header. -/
def formatFromHeader? (patch : Patch) : Option PatchFormat :=
  let matchingEntry? :=
    formatsByHeader.find? (fun (header, _) => patch.extract 0 header.size == header)
  matchingEntry?.map (fun (_, format) => format)

end RompatcherDX.PatchFormats
