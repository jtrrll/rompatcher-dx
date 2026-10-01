import RompatcherDX.Cli.Root

def main (args : List String) : IO UInt32 :=
  RompatcherDX.Cli.Root.cmd.validate args
