import RompatcherDX.PatchFormats.Detection
import RompatcherDX.PatchFormats.IPS.Impl

/-!
# ROM patching library implementation

This module implements the rompatcher-dx library operations.
-/

namespace RompatcherDX

/-- Applies the patches to `rom` in order, decoding each patch in the format it is paired with. -/
def apply_patches (rom : ROM) (patches : List (PatchFormats.PatchFormat × Patch)) :
    Except String ROM :=
  let applyPatch (rom : ROM) (formattedPatch : PatchFormats.PatchFormat × Patch) :
      Except String ROM :=
    match formattedPatch with
    | (PatchFormats.PatchFormat.ips, patch) => PatchFormats.IPS.apply rom patch
  patches.foldlM applyPatch rom

/-- Creates a patch in `format` that transforms `unpatchedRom` into `patchedRom`. -/
def create_patch (unpatchedRom patchedRom : ROM)
  (format : PatchFormats.PatchFormat) : Except String Patch :=
  match format with
  | PatchFormats.PatchFormat.ips => PatchFormats.IPS.create unpatchedRom patchedRom

end RompatcherDX
