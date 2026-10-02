/-!
# Binary command-line input and output

This module reads and writes ROMs and patches through files or standard streams.
-/

namespace RompatcherDX.Cli

/-- Reads binary input from `path?`, or from standard input when no path is given. -/
def readInput (path? : Option String) : IO ByteArray :=
  match path? with
  | some path => IO.FS.readBinFile (System.FilePath.mk path)
  | none => do
    let stdin ← IO.getStdin
    stdin.readBinToEnd

/-- Writes bytes to `path?`, or to standard output when no path is given. -/
def writeOutput (path? : Option String) (bytes : ByteArray) : IO Unit :=
  match path? with
  | some path => IO.FS.writeBinFile (System.FilePath.mk path) bytes
  | none => do
    let stdout ← IO.getStdout
    stdout.write bytes
    stdout.flush

end RompatcherDX.Cli
