module

/-!
# Unsigned three-byte integers

This module defines a 24-bit unsigned integer type for binary formats with three-byte fields.
-/

namespace RompatcherDX.Bytes

/-- An unsigned three-byte integer. -/
public abbrev UInt24 := { bits : UInt32 // bits < 0x1000000 }

/-- Converts `number` to a three-byte integer. -/
public def UInt24.ofNat? (number : Nat) : Option UInt24 :=
  if isInRange : number < 0x1000000 then
    some {
      val := number.toUInt32
      property := by
        simp [UInt32.lt_iff_toNat_lt, Nat.toUInt32_eq]
        omega
    }
  else
    none

/-- Converts `bits` to a three-byte integer. -/
public def UInt24.ofUInt32? (bits : UInt32) : Option UInt24 :=
  if isInRange : bits < 0x1000000 then
    some { val := bits, property := isInRange }
  else
    none

/-- Converts a three-byte integer to a natural number. -/
public def UInt24.toNat (value : UInt24) : Nat :=
  value.val.toNat

/-- Converts a three-byte integer to the `UInt32` that stores it. -/
public def UInt24.toUInt32 (value : UInt24) : UInt32 :=
  value.val

end RompatcherDX.Bytes
