import RompatcherDx.Cli.Root

def main (args : List String) : IO UInt32 :=
  RompatcherDx.Cli.Root.cmd.validate args
