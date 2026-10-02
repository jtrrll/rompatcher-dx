import RompatcherDX.Cli.Root

/-!
# rompatcher-dx executable

This module starts the rompatcher-dx command-line interface.
-/

/-- Runs the rompatcher-dx command-line interface. -/
def main (args : List String) : IO UInt32 :=
  RompatcherDX.Cli.Root.cmd.validate args
