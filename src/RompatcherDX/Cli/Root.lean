import RompatcherDX.Cli.Apply
import RompatcherDX.Cli.Create

/-!
# rompatcher-dx command

This module combines the apply and create subcommands under the root command.
-/

namespace RompatcherDX.Cli.Root

open _root_.Cli

/-- Prints root-command help when no subcommand is provided. -/
private def run (parsed : Parsed) : IO UInt32 := do
  parsed.printHelp
  return 2

/-- The root command of the rompatcher-dx CLI. -/
def cmd : Cmd := `[Cli|
  "rompatcher-dx" VIA run;
  "A ROM patching library and CLI."

  SUBCOMMANDS:
    Apply.cmd;
    Create.cmd
]

end RompatcherDX.Cli.Root
