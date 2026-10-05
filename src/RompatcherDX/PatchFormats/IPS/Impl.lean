module

public import RompatcherDX.TypeAliases
import RompatcherDX.Bytes.UInt24.Impl
import Std.Tactic.BVDecide
meta import Std.Tactic.BVDecide.Reflect

/-!
# International Patching System (IPS)

This module implements the IPS patch format.
-/

namespace RompatcherDX.PatchFormats.IPS

open RompatcherDX.Bytes

/-- The magic header identifying an IPS patch. -/
private def header : ByteArray := "PATCH".toUTF8

/-- The marker ending the sequence of IPS patch records. -/
private def endMarker : ByteArray := "EOF".toUTF8

/-- An IPS patch record writes a regular payload or repeats one byte. -/
private inductive PatchRecord where
  /-- Writes `patch` at the given offset. -/
  | regular (offset : UInt24) (patch : ByteArray)
  /-- Writes `value` `runLength` times at the given offset. -/
  | rle (offset : UInt24) (runLength : UInt16) (value : UInt8)

/-- The contents of an IPS patch. -/
private structure PatchContents where
  /-- The patch records, in the order they are applied. -/
  records : Array PatchRecord
  /-- The exact size of the patched ROM, stored in an optional trailer after the end marker. -/
  finalSize : Option UInt24

/-- Reads the unsigned two-byte big-endian number stored at `pos`, if those bytes exist. -/
private def readU16? (bytes : ByteArray) (pos : Nat) : Option UInt16 :=
  if hasTwoBytes : pos + 2 ≤ bytes.size then
    let high := bytes[pos]
    let low := bytes[pos + 1]
    some ((high.toUInt16 <<< 8) ||| low.toUInt16)
  else
    none

/-- Reads the unsigned three-byte big-endian number stored at `pos`, if those bytes exist. -/
private def readU24? (bytes : ByteArray) (pos : Nat) : Option UInt24 :=
  if hasThreeBytes : pos + 3 ≤ bytes.size then
    let high := bytes[pos]
    let middle := bytes[pos + 1]
    let low := bytes[pos + 2]
    some {
      val := (high.toUInt32 <<< 16) ||| (middle.toUInt32 <<< 8) ||| low.toUInt32
      property := by
        bv_decide
    }
  else
    none

/-- Appends `value` as an unsigned two-byte big-endian number. -/
private def writeU16 (bytes : ByteArray) (value : UInt16) : ByteArray :=
  let high := (value >>> 8).toUInt8
  let low := value.toUInt8
  (bytes.push high).push low

/-- Appends `value` as an unsigned three-byte big-endian number. -/
private def writeU24 (bytes : ByteArray) (value : UInt24) : ByteArray :=
  let bits := value.toUInt32
  let high := (bits >>> 16).toUInt8
  let middle := (bits >>> 8).toUInt8
  let low := bits.toUInt8
  ((bytes.push high).push middle).push low

/-- Decodes the contents of an IPS patch. -/
private def decode (patch : Patch) : Except String PatchContents := do
  if patch.size < header.size || patch.extract 0 header.size != header then
    throw "rompatcher-dx IPS: missing PATCH header"
  decodeRecords patch header.size #[]
where
  /-- Decodes the IPS patch records starting at `pos`, appending them to `records`, followed by the
  end marker and optional final-size trailer. -/
  decodeRecords (bytes : Patch) (pos : Nat) (records : Array PatchRecord) :
      Except String PatchContents :=
    if bytes.size ≤ pos then
      Except.error "rompatcher-dx IPS: missing EOF marker"
    else do
      if bytes.extract pos (pos + 3) == endMarker then
        let markerEnd := pos + 3
        if markerEnd == bytes.size then
          return { records := records, finalSize := none }
        let some finalSize := readU24? bytes markerEnd
          | throw "rompatcher-dx IPS: unexpected data after EOF marker"
        if markerEnd + 3 != bytes.size then
          throw "rompatcher-dx IPS: unexpected data after EOF marker"
        return { records := records, finalSize := some finalSize }
      let some offset := readU24? bytes pos
        | throw "rompatcher-dx IPS: truncated record offset"
      let some length := readU16? bytes (pos + 3)
        | throw "rompatcher-dx IPS: truncated record length"
      let isRLERecord := length == 0
      if isRLERecord then
        let some runLength := readU16? bytes (pos + 5)
          | throw "rompatcher-dx IPS: truncated RLE record"
        let some value := bytes[pos + 7]?
          | throw "rompatcher-dx IPS: truncated RLE record"
        decodeRecords bytes (pos + 8) (records.push (PatchRecord.rle offset runLength value))
      else
        let payloadEnd := pos + 5 + length.toNat
        if payloadEnd > bytes.size then
          throw "rompatcher-dx IPS: truncated regular record"
        let payload := bytes.extract (pos + 5) payloadEnd
        decodeRecords bytes payloadEnd (records.push (PatchRecord.regular offset payload))
  termination_by bytes.size - pos
  decreasing_by
    all_goals omega

/-- Encodes one IPS patch record. -/
private def encodeRecord (record : PatchRecord) : Except String ByteArray := do
  let (offset, encodedBody) ← match record with
    | PatchRecord.regular offset patch =>
      if lengthFits : 0 < patch.size ∧ patch.size < UInt16.size then
        let encodedLength := UInt16.ofNatLT patch.size lengthFits.right
        Except.ok (offset, writeU16 ByteArray.empty encodedLength ++ patch)
      else
        Except.error "rompatcher-dx IPS: regular record payload must be 1 to 65535 bytes"
    | PatchRecord.rle offset runLength value =>
      let rleMarker := writeU16 ByteArray.empty 0
      let withRunLength := writeU16 rleMarker runLength
      Except.ok (offset, withRunLength.push value)
  let encodedOffset := writeU24 ByteArray.empty offset
  if encodedOffset == endMarker then
    throw "rompatcher-dx IPS: record offset is reserved for the EOF marker"
  return encodedOffset ++ encodedBody

/-- Encodes the contents of an IPS patch. -/
private def encode (contents : PatchContents) : Except String Patch := do
  let encodedRecords ← contents.records.mapM encodeRecord
  let appendBytes (bytes encodedRecord : ByteArray) := bytes ++ encodedRecord
  let withRecords := encodedRecords.foldl appendBytes header
  let withEndMarker := withRecords ++ endMarker
  match contents.finalSize with
  | some finalSize => return writeU24 withEndMarker finalSize
  | none => return withEndMarker

/-- Resizes `rom` to exactly `size` bytes, truncating it or padding it with zero bytes. -/
private def resize (rom : ROM) (size : Nat) : ROM :=
  if size ≤ rom.size then
    rom.extract 0 size
  else
    rom ++ ByteArray.mk (Array.replicate (size - rom.size) 0)

/-- Writes `bytes` into `rom` at `offset`, first padding `rom` with zero bytes if they do not fit. -/
private def writeAt (rom : ROM) (offset : Nat) (bytes : ByteArray) : ROM :=
  let requiredSize := offset + bytes.size
  let padded := if rom.size < requiredSize then resize rom requiredSize else rom
  bytes.copySlice 0 padded offset bytes.size

/-- Applies one IPS patch record to `rom`. -/
private def applyRecord (rom : ROM) (record : PatchRecord) : ROM :=
  match record with
  | PatchRecord.regular offset patch => writeAt rom offset.toNat patch
  | PatchRecord.rle offset runLength value =>
    let run := ByteArray.mk (Array.replicate runLength.toNat value)
    writeAt rom offset.toNat run

/-- Applies an IPS patch to a ROM. -/
public def apply (rom : ROM) (patch : Patch) : Except String ROM := do
  let contents ← decode patch
  let patchedRom := contents.records.foldl applyRecord rom
  match contents.finalSize with
  | some finalSize => return resize patchedRom finalSize.toNat
  | none => return patchedRom

/-- Whether a record must write `patched`'s byte at `pos`, either because `unpatched` has a
different byte there or because a ROM grown to the size of `patched` would have a different
padding byte there. The last byte of a grown ROM is always written, so that `apply` grows the ROM
to the full size. -/
private def mustWrite (unpatched patched : ROM) (pos : Nat) : Bool :=
  let isLastByte := pos + 1 == patched.size
  if pos < unpatched.size then
    unpatched[pos]? != patched[pos]?
  else
    patched[pos]? != some 0 || isLastByte

/-- Finds the end of the run of bytes that must be written, starting at `pos` and stopping at
`limit`. -/
private def runEnd (unpatched patched : ROM) (pos limit : Nat) : Nat :=
  if pos < limit then
    if mustWrite unpatched patched pos then
      runEnd unpatched patched (pos + 1) limit
    else
      pos
  else
    pos
termination_by limit - pos

/-- A run of bytes that must be written never ends before it starts. -/
private theorem le_runEnd (unpatched patched : ROM) (pos limit : Nat) :
    pos ≤ runEnd unpatched patched pos limit := by
  fun_induction runEnd unpatched patched pos limit
  all_goals omega

/-- Picks the offset of a record that writes the byte at `pos`: `pos` itself when IPS can encode it,
otherwise the closest earlier offset that it can encode. -/
private def recordStart? (pos : Nat) : Option UInt24 := do
  let offset ← UInt24.ofNat? (min pos 0xFFFFFF)
  if writeU24 ByteArray.empty offset == endMarker then
    UInt24.ofNat? (offset.toNat - 1)
  else
    some offset

/-- The position a record starting at `start` must end at or before: IPS payloads hold at most
65535 bytes, and records never extend past the end of `patched`. -/
private def recordLimit (patched : ROM) (start : UInt24) : Nat :=
  min patched.size (start.toNat + 0xFFFF)

/-- Creates an IPS patch from two ROMs. -/
public def create (unpatched patched : ROM) : Except String Patch := do
  let mut finalSize := none
  if patched.size < unpatched.size then
    let some size := UInt24.ofNat? patched.size
      | throw "rompatcher-dx IPS: cannot shrink a ROM to 16 MiB or more"
    finalSize := some size
  let records ← createRecords unpatched patched 0 #[]
  encode { records := records, finalSize := finalSize }
where
  /-- Creates regular records, starting at `pos` and appending them to `records`, that write every
  byte of `patched` that must be written. -/
  createRecords (unpatched patched : ROM) (pos : Nat) (records : Array PatchRecord) :
      Except String (Array PatchRecord) :=
    if patched.size ≤ pos then
      Except.ok records
    else if mustWrite unpatched patched pos then
      match recordStart? pos with
      | none => Except.error "rompatcher-dx IPS: ROMs differ beyond the IPS offset limit"
      | some start =>
        if recordLimit patched start ≤ pos then
          Except.error "rompatcher-dx IPS: ROMs differ beyond the IPS offset limit"
        else
          let recordEnd := runEnd unpatched patched (pos + 1) (recordLimit patched start)
          let payload := patched.extract start.toNat recordEnd
          let record := PatchRecord.regular start payload
          createRecords unpatched patched recordEnd (records.push record)
    else
      createRecords unpatched patched (pos + 1) records
  termination_by patched.size - pos
  decreasing_by
    next =>
      have recordEndIsAfterPos :=
        le_runEnd unpatched patched (pos + 1) (recordLimit patched start)
      omega
    next =>
      omega

end RompatcherDX.PatchFormats.IPS
