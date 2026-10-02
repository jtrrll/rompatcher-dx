import RompatcherDX.Bytes.UInt24
import RompatcherDX.TypeAliases
import Std.Tactic.BVDecide

/-!
# International Patching System (IPS)

This module contains the IPS patch-format implementation.
-/

namespace RompatcherDX.PatchFormats.IPS

open RompatcherDX.Bytes

/-- The magic header identifying an IPS patch. -/
def header : ByteArray := "PATCH".toUTF8

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

/-- Encodes the contents of an IPS patch. -/
private def encode (contents : PatchContents) : Except String Patch := do
  let mut bytes := header
  for record in contents.records do
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
    bytes := bytes ++ encodedOffset ++ encodedBody
  bytes := bytes ++ endMarker
  match contents.finalSize with
  | some finalSize => return writeU24 bytes finalSize
  | none => return bytes

/-- Encoding IPS patch contents yields a patch exactly when decoding that patch yields the
contents. -/
private theorem encode_eq_ok_iff_decode_eq_ok
    (contents : PatchContents)
    (patch : Patch) :
    encode contents = Except.ok patch ↔ decode patch = Except.ok contents := by
  constructor
  case mp =>
    intro encodingSucceeded
    sorry
  case mpr =>
    intro decodingSucceeded
    sorry

/-- Applies an IPS patch to a ROM. -/
def apply (_rom : ROM) (_patch : Patch) : Except String ROM :=
  Except.error "rompatcher-dx IPS: apply not implemented"

/-- Creates an IPS patch from two ROMs. -/
def create (_original _modified : ROM) : Except String Patch :=
  Except.error "rompatcher-dx IPS: create not implemented"

/-- Applying a successfully created IPS patch to the original ROM yields the same patched ROM. -/
theorem applying_created_patch_returns_patched_rom
    (unpatched patched : ROM)
    (patch : Patch)
    (createPatchSucceeded : create unpatched patched = Except.ok patch) :
    apply unpatched patch = Except.ok patched := by
  sorry

/-- Creating an IPS patch succeeds whenever some IPS patch turns the original ROM into the patched
ROM. The created patch need not equal that patch, because different IPS patches can have the same
effect. -/
theorem creating_patch_succeeds_when_some_patch_produces_patched_rom
    (unpatched patched : ROM)
    (patch : Patch)
    (applyPatchSucceeded : apply unpatched patch = Except.ok patched) :
    ∃ createdPatch, create unpatched patched = Except.ok createdPatch := by
  sorry

end RompatcherDX.PatchFormats.IPS
