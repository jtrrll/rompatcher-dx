import Cli
import RompatcherDX
import RompatcherDX.Cli.IO

/-!
# Create command

This module creates a patch from an unpatched ROM and a patched ROM.
-/

namespace RompatcherDX.Cli.Create

open _root_.Cli

/-- Parses the patch format supplied to the create command. -/
private instance patchFormatParser : ParseableType RompatcherDX.PatchFormats.PatchFormat where
  name := ParseableType.name String
  parse? := RompatcherDX.PatchFormats.PatchFormat.parse?

/-- Reads the source and destination ROMs and writes the created patch. -/
private def run (parsed : Parsed) : IO UInt32 := do
  match parsed.flag? "format" with
  | none =>
    IO.eprintln "rompatcher-dx create: --format is required"
    return 2
  | some formatFlag =>
    match formatFlag.as? RompatcherDX.PatchFormats.PatchFormat with
    | none =>
      IO.eprintln "rompatcher-dx create: invalid patch format"
      return 2
    | some format =>
      try
        let unpatchedRomPath := System.FilePath.mk (parsed.positionalArg! "unpatched-rom").value
        let unpatched ← IO.FS.readBinFile unpatchedRomPath
        let patched ← Cli.readInput
          ((parsed.flag? "patched-rom").map (fun patchedRomFlag => patchedRomFlag.value))
        match RompatcherDX.create_patch unpatched patched format with
        | Except.error message =>
          IO.eprintln message
          return (1 : UInt32)
        | Except.ok patch =>
          Cli.writeOutput ((parsed.flag? "output").map (fun outputFlag => outputFlag.value)) patch
          return (0 : UInt32)
      catch error =>
        IO.eprintln s!"rompatcher-dx create: {error}"
        return (1 : UInt32)

/-- The command-line interface for creating a patch in the requested format. -/
def cmd : Cmd := `[Cli|
  "create" VIA run;
  "Create a patch from an unpatched ROM and a patched ROM read from stdin by default, writing the patch to stdout."

  FLAGS:
    "patched-rom" : String; "Read the patched ROM from a file instead of stdin."
    o, output : String; "Write the patch to a file instead of stdout."
    f, format : RompatcherDX.PatchFormats.PatchFormat; "Patch format to create (required)."

  ARGS:
    "unpatched-rom" : String; "File containing the unpatched ROM."
]

end RompatcherDX.Cli.Create
