import Cli
import RompatcherDX
import RompatcherDX.Cli.IO

/-!
# Apply command

This module reads patch files and applies them to a ROM from a file or standard input.
-/

namespace RompatcherDX.Cli.Apply

open _root_.Cli

/-- Reads and applies the requested patches, then writes the resulting ROM. -/
private def run (parsed : Parsed) : IO UInt32 := do
  if parsed.variableArgs.isEmpty then
    IO.eprintln "rompatcher-dx apply: at least one patch file is required"
    return 1
  try
    let rom ← Cli.readInput ((parsed.flag? "input").map (fun inputFlag => inputFlag.value))
    let patches ← parsed.variableArgs.toList.mapM (fun patchArgument =>
      IO.FS.readBinFile (System.FilePath.mk patchArgument.value))
    match RompatcherDX.apply_patches rom patches with
    | Except.error message =>
      IO.eprintln message
      return (1 : UInt32)
    | Except.ok patched =>
      Cli.writeOutput ((parsed.flag? "output").map (fun outputFlag => outputFlag.value)) patched
      return (0 : UInt32)
  catch error =>
    IO.eprintln s!"rompatcher-dx apply: {error}"
    return (1 : UInt32)

/-- The command-line interface for applying ordered patch files to a ROM. -/
def cmd : Cmd := `[Cli|
  "apply" VIA run;
  "Apply one or more patches to a ROM, reading from stdin and writing to stdout by default."

  FLAGS:
    i, input : String;  "Read the unpatched ROM from a file instead of stdin."
    o, output : String; "Write the patched ROM to a file instead of stdout."

  ARGS:
    ...patches : String; "Patch files to apply in order (at least one required)."
]

end RompatcherDX.Cli.Apply
