import RompatcherDX.TypeAliases
import RompatcherDX.PatchFormats.IPS

namespace RompatcherDX.PatchFormats

inductive PatchFormat where
  | ips

def PatchFormat.parse? (name : String) : Option PatchFormat :=
  match name.toLower with
  | "ips" => some .ips
  | _ => none

private def formatsByHeader : List (ByteArray × PatchFormat) :=
  [(IPS.header, PatchFormat.ips)]

def formatFromHeader? (patch : Patch) : Option PatchFormat :=
  (formatsByHeader.find? (fun entry => patch.extract 0 entry.1.size == entry.1)).map Prod.snd

end RompatcherDX.PatchFormats
