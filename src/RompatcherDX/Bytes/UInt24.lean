/-!
# Unsigned three-byte integers

This module defines a 24-bit unsigned integer type for binary formats with three-byte fields.
-/

namespace RompatcherDX.Bytes

/-- An unsigned three-byte integer. -/
abbrev UInt24 := { bits : UInt32 // bits < 0x1000000 }

/-- Converts `number` to a three-byte integer. -/
def UInt24.ofNat? (number : Nat) : Option UInt24 :=
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
def UInt24.ofUInt32? (bits : UInt32) : Option UInt24 :=
  if isInRange : bits < 0x1000000 then
    some { val := bits, property := isInRange }
  else
    none

/-- Converts a three-byte integer to a natural number. -/
def UInt24.toNat (value : UInt24) : Nat :=
  value.val.toNat

/-- Converts a three-byte integer to the `UInt32` that stores it. -/
def UInt24.toUInt32 (value : UInt24) : UInt32 :=
  value.val

/-- A three-byte integer is less than `2^24`. -/
theorem UInt24.toNat_lt (value : UInt24) : value.toNat < 2^24 := by
  obtain ⟨bits, bitsAreInRange⟩ := value
  have bitsAsNatAreInRange : bits.toNat < 0x1000000 := UInt32.lt_iff_toNat_lt.mp bitsAreInRange
  simp [UInt24.toNat]
  omega

/-- Two three-byte integers are equal exactly when their numeric values are equal. -/
theorem UInt24.toNat_inj {firstValue secondValue : UInt24} :
    firstValue.toNat = secondValue.toNat ↔ firstValue = secondValue := by
  obtain ⟨firstBits, _⟩ := firstValue
  obtain ⟨secondBits, _⟩ := secondValue
  simp [UInt24.toNat, UInt32.toNat_inj]

/-- Converting a number to a three-byte integer and back gives the original number. -/
theorem UInt24.toNat_of_ofNat?_eq_some {number : Nat} {value : UInt24}
    (conversionSucceeded : UInt24.ofNat? number = some value) : value.toNat = number := by
  unfold UInt24.ofNat? at conversionSucceeded
  split at conversionSucceeded
  case isTrue =>
    injection conversionSucceeded with valueIsConverted
    subst valueIsConverted
    simp [UInt24.toNat, Nat.toUInt32_eq]
    omega
  case isFalse =>
    contradiction

/-- Converting a three-byte integer to a number and back gives the original integer. -/
theorem UInt24.ofNat?_toNat (value : UInt24) : UInt24.ofNat? value.toNat = some value := by
  obtain ⟨bits, bitsAreInRange⟩ := value
  have bitsAsNatAreInRange : bits.toNat < 0x1000000 := UInt32.lt_iff_toNat_lt.mp bitsAreInRange
  simp [UInt24.ofNat?, UInt24.toNat, bitsAsNatAreInRange]

/-- Conversion to a three-byte integer fails exactly when the number is at least `2^24`. -/
theorem UInt24.ofNat?_eq_none_iff {number : Nat} :
    UInt24.ofNat? number = none ↔ 0x1000000 ≤ number := by
  unfold UInt24.ofNat?
  split
  case isTrue =>
    simp
    omega
  case isFalse =>
    simp
    omega

end RompatcherDX.Bytes
