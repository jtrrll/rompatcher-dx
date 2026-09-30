import RompatcherDx.PatchFormat

namespace RompatcherDx

def apply (rom : ByteArray) (patches : List ByteArray) : Except String ByteArray :=
  match patches with
  | [] => Except.ok rom
  | _ :: _ => Except.error "rompatcher-dx apply: not implemented"

def create (_unpatchedRom _patchedRom : ByteArray) (_format : PatchFormat) : Except String ByteArray :=
  Except.error "rompatcher-dx create: not implemented"

theorem apply_empty (rom : ByteArray) :
    apply rom [] = Except.ok rom := by
  rfl

theorem apply_append (rom : ByteArray) (first second : List ByteArray) :
    apply rom (first ++ second) =
      (apply rom first).bind (fun intermediate => apply intermediate second) := by
  sorry

theorem create_apply_roundtrip
    (unpatched patched : ByteArray)
    (format : PatchFormat)
    (patch : ByteArray)
    (hCreate : create unpatched patched format = Except.ok patch) :
    apply unpatched [patch] = Except.ok patched := by
  sorry

structure CreatedPatch where
  format : PatchFormat
  patchedRom : ByteArray
  patch : ByteArray

def CreatedPatchChain (source : ByteArray) : List CreatedPatch → ByteArray → Prop
  | [], destination => source = destination
  | step :: rest, destination =>
    create source step.patchedRom step.format = Except.ok step.patch ∧
      CreatedPatchChain step.patchedRom rest destination

theorem create_apply_chain_roundtrip
    (source destination : ByteArray)
    (steps : List CreatedPatch)
    (hChain : CreatedPatchChain source steps destination) :
    apply source (steps.map CreatedPatch.patch) = Except.ok destination := by
  sorry

end RompatcherDx
