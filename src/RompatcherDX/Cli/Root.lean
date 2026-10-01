import RompatcherDX.Cli.Apply
import RompatcherDX.Cli.Create

namespace RompatcherDX.Cli.Root

open _root_.Cli

private def run (parsed : Parsed) : IO UInt32 := do
  parsed.printHelp
  return 2

def cmd : Cmd := `[Cli|
  "rompatcher-dx" VIA run;
  "A ROM patching library and CLI."

  SUBCOMMANDS:
    Apply.cmd;
    Create.cmd
]

end RompatcherDX.Cli.Root
