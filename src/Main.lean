import Cli

open Cli

private def runApply (parsed : Parsed) : IO UInt32 := do
  if parsed.variableArgs.isEmpty then
    IO.eprintln "rompatcher-dx apply: at least one patch file is required"
    return 1
  IO.eprintln "rompatcher-dx apply: not implemented"
  return 1

private def runCreate (_ : Parsed) : IO UInt32 := do
  IO.eprintln "rompatcher-dx create: not implemented"
  return 1

private def runRoot (parsed : Parsed) : IO UInt32 := do
  parsed.printHelp
  return 2

private def applyCmd : Cmd := `[Cli|
  apply VIA runApply;
  "Apply one or more patches to a ROM, reading from stdin and writing to stdout by default."

  FLAGS:
    i, input : String;  "Read the unpatched ROM from a file instead of stdin."
    o, output : String; "Write the patched ROM to a file instead of stdout."

  ARGS:
    ...patches : String; "Patch files to apply in order (at least one required)."
]

private def createCmd : Cmd := `[Cli|
  create VIA runCreate;
  "Create a patch from an unpatched ROM and a patched ROM read from stdin by default, writing the patch to stdout."

  FLAGS:
    "patched-rom" : String; "Read the patched ROM from a file instead of stdin."
    o, output : String; "Write the patch to a file instead of stdout."
    f, format : String; "Patch format to create."

  ARGS:
    "unpatched-rom" : String; "File containing the unpatched ROM."
]

private def rompatcherCmd : Cmd := `[Cli|
  "rompatcher-dx" VIA runRoot;
  "A ROM patching library and CLI."

  SUBCOMMANDS:
    applyCmd;
    createCmd
]

def main (args : List String) : IO UInt32 :=
  rompatcherCmd.validate args
