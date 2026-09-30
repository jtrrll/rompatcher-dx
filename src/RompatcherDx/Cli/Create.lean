import Cli
import RompatcherDx
import RompatcherDx.Cli.IO

namespace RompatcherDx.Cli.Create

open _root_.Cli

private instance : ParseableType RompatcherDx.PatchFormat where
  name := (inferInstance : ParseableType String).name
  parse? := RompatcherDx.PatchFormat.parse?

private def run (parsed : Parsed) : IO UInt32 := do
  let some flag := parsed.flag? "format" | do
    IO.eprintln "rompatcher-dx create: --format is required"
    return 2
  match flag.as? RompatcherDx.PatchFormat with
  | none =>
    IO.eprintln "rompatcher-dx create: invalid patch format"
    return 2
  | some format =>
    try
      let unpatched ← IO.FS.readBinFile ⟨(parsed.positionalArg! "unpatched-rom").value⟩
      let patched ← Cli.readInput ((parsed.flag? "patched-rom").map (·.value))
      match RompatcherDx.create unpatched patched format with
      | Except.error message =>
        IO.eprintln message
        return (1 : UInt32)
      | Except.ok patch =>
        Cli.writeOutput ((parsed.flag? "output").map (·.value)) patch
        return (0 : UInt32)
    catch error =>
      IO.eprintln s!"rompatcher-dx create: {error}"
      return (1 : UInt32)

def cmd : Cmd := `[Cli|
  "create" VIA run;
  "Create a patch from an unpatched ROM and a patched ROM read from stdin by default, writing the patch to stdout."

  FLAGS:
    "patched-rom" : String; "Read the patched ROM from a file instead of stdin."
    o, output : String; "Write the patch to a file instead of stdout."
    f, format : RompatcherDx.PatchFormat; "Patch format to create (required)."

  ARGS:
    "unpatched-rom" : String; "File containing the unpatched ROM."
]

end RompatcherDx.Cli.Create
