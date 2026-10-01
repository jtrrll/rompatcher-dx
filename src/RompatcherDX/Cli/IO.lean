namespace RompatcherDX.Cli

def readInput (path? : Option String) : IO ByteArray :=
  match path? with
  | some path => IO.FS.readBinFile ⟨path⟩
  | none => do
    let stdin ← IO.getStdin
    stdin.readBinToEnd

def writeOutput (path? : Option String) (bytes : ByteArray) : IO Unit :=
  match path? with
  | some path => IO.FS.writeBinFile ⟨path⟩ bytes
  | none => do
    let stdout ← IO.getStdout
    stdout.write bytes
    stdout.flush

end RompatcherDX.Cli
