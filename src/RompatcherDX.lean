import RompatcherDX.PatchFormats.Detection

/-!
# ROM patching library

This module provides the rompatcher-dx library operations and their correctness properties.
-/

namespace RompatcherDX

/-- Applies the patches to `rom` in order. -/
def apply_patches (rom : ROM) (patches : List Patch) : Except String ROM :=
  let applyPatch (rom : ROM) (bytes : Patch) : Except String ROM :=
    match PatchFormats.formatFromHeader? bytes with
    | some PatchFormats.PatchFormat.ips => PatchFormats.IPS.apply rom bytes
    | none => Except.error "rompatcher-dx apply: unrecognized patch format"
  patches.foldlM applyPatch rom

/-- Creates a patch in `format` that transforms `unpatchedRom` into `patchedRom`. -/
def create_patch (unpatchedRom patchedRom : ROM)
  (format : PatchFormats.PatchFormat) : Except String Patch :=
  match format with
  | PatchFormats.PatchFormat.ips => PatchFormats.IPS.create unpatchedRom patchedRom

/-- Applying no patches returns the original ROM. -/
theorem applying_no_patches_returns_original_rom (rom : ROM) :
    apply_patches rom [] = Except.ok rom := by
  rfl

/-- Applying a list of patches is equivalent to applying its members one at a time. -/
theorem applying_patches_together_matches_sequential (rom : ROM) (patches : List Patch) :
    apply_patches rom patches =
      patches.foldlM (fun intermediate patch => apply_patches intermediate [patch]) rom := by
  simp [apply_patches]

/-- Applying a successfully created patch yields the patched ROM. -/
theorem applying_created_patch_returns_patched_rom
    (unpatched patched : ROM)
    (format : PatchFormats.PatchFormat)
    (patch : Patch)
    (creationSucceeded : create_patch unpatched patched format = Except.ok patch) :
    apply_patches unpatched [patch] = Except.ok patched := by
  sorry

/-- A patch created for one step of a ROM transformation. -/
structure CreatedPatch where
  /-- The ROM produced by this step. -/
  patchedRom : ROM
  /-- The format used to create this patch. -/
  format : PatchFormats.PatchFormat
  /-- The bytes of the created patch. -/
  patch : Patch

/-- Relates a source ROM to a destination through successfully created patches. -/
def CreatedPatchChain (source : ROM) : List CreatedPatch → ROM → Prop
  | [], destination => source = destination
  | step :: rest, destination =>
    create_patch source step.patchedRom step.format = Except.ok step.patch ∧
      CreatedPatchChain step.patchedRom rest destination

/-- Applying a chain of successfully created patches yields its destination ROM. -/
theorem applying_chain_of_created_patches_returns_destination_rom
    (source destination : ROM)
    (steps : List CreatedPatch)
    (patchesWereCreated : CreatedPatchChain source steps destination) :
    apply_patches source (steps.map CreatedPatch.patch) = Except.ok destination := by
  sorry

end RompatcherDX
