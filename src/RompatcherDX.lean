import RompatcherDX.PatchFormats.Detection

namespace RompatcherDX

def apply_patches (rom : ROM) (patches : List Patch) : Except String ROM :=
  let applyPatch (rom : ROM) (bytes : Patch) : Except String ROM :=
    match PatchFormats.formatFromHeader? bytes with
    | some PatchFormats.PatchFormat.ips => PatchFormats.IPS.apply rom bytes
    | none => Except.error "rompatcher-dx apply: unrecognized patch format"
  patches.foldlM applyPatch rom

def create_patch (unpatchedRom patchedRom : ROM)
  (format : PatchFormats.PatchFormat) : Except String Patch :=
  match format with
  | PatchFormats.PatchFormat.ips => PatchFormats.IPS.create unpatchedRom patchedRom

theorem applying_no_patches_returns_original_rom (rom : ROM) :
    apply_patches rom [] = Except.ok rom := by
  rfl

theorem applying_patches_together_matches_sequential (rom : ROM) (patches : List ByteArray) :
    apply_patches rom patches =
      patches.foldlM (fun intermediate patch => apply_patches intermediate [patch]) rom := by
  have singleton (current : ROM) (patch : Patch) :
      apply_patches current [patch] =
        match PatchFormats.formatFromHeader? patch with
        | some PatchFormats.PatchFormat.ips => PatchFormats.IPS.apply current patch
        | none => Except.error "rompatcher-dx apply: unrecognized patch format" := by
    simp [apply_patches]
  simp only [singleton]
  rfl

theorem applying_created_patch_returns_patched_rom
    (unpatched patched : ROM)
    (format : PatchFormats.PatchFormat)
    (patch : Patch)
    (hCreate : create_patch unpatched patched format = Except.ok patch) :
    apply_patches unpatched [patch] = Except.ok patched := by
  sorry

structure CreatedPatch where
  patchedRom : ROM
  format : PatchFormats.PatchFormat
  patch : Patch

def CreatedPatchChain (source : ROM) : List CreatedPatch → ROM → Prop
  | [], destination => source = destination
  | step :: rest, destination =>
    create_patch source step.patchedRom step.format = Except.ok step.patch ∧
      CreatedPatchChain step.patchedRom rest destination

theorem applying_chain_of_created_patches_returns_destination_rom
    (source destination : ROM)
    (steps : List CreatedPatch)
    (hChain : CreatedPatchChain source steps destination) :
    apply_patches source (steps.map CreatedPatch.patch) = Except.ok destination := by
  sorry

end RompatcherDX
