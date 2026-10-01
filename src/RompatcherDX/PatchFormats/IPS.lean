import RompatcherDX.TypeAliases

namespace RompatcherDX.PatchFormats.IPS

def header : ByteArray := ⟨#[80, 65, 84, 67, 72]⟩

def apply (_rom : ROM) (_patch : Patch) : Except String ROM :=
  Except.error "rompatcher-dx IPS: apply not implemented"

def create (_original _modified : ROM) : Except String Patch :=
  Except.error "rompatcher-dx IPS: create not implemented"

end RompatcherDX.PatchFormats.IPS
