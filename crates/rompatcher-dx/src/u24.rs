//! Unsigned three-byte integers for binary formats with three-byte fields.

/// An unsigned three-byte integer.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct U24(u32);

impl U24 {
    /// The largest three-byte integer.
    const MAX_BITS: u32 = 0xFF_FFFF;

    /// Converts `number` to a three-byte integer, if it is in range.
    #[expect(
        clippy::cast_possible_truncation,
        reason = "the range check guarantees that the cast is lossless"
    )]
    pub const fn from_usize(number: usize) -> Option<Self> {
        if number <= Self::MAX_BITS as usize {
            Some(Self(number as u32))
        } else {
            None
        }
    }

    /// Reads a three-byte integer from its big-endian bytes.
    pub const fn from_be_bytes(bytes: [u8; 3]) -> Self {
        let high = bytes[0] as u32;
        let middle = bytes[1] as u32;
        let low = bytes[2] as u32;
        Self((high << 16) | (middle << 8) | low)
    }

    /// Writes a three-byte integer as big-endian bytes.
    #[expect(
        clippy::cast_possible_truncation,
        reason = "each cast keeps exactly one byte"
    )]
    pub const fn to_be_bytes(self) -> [u8; 3] {
        let bits = self.0;
        [(bits >> 16) as u8, (bits >> 8) as u8, bits as u8]
    }

    /// Converts a three-byte integer to a `usize`.
    pub const fn to_usize(self) -> usize {
        self.0 as usize
    }
}

#[cfg(test)]
mod tests {
    use super::U24;

    #[test]
    fn rejects_numbers_out_of_range() {
        assert_eq!(U24::from_usize(0x100_0000), None);
    }

    #[test]
    fn round_trips_big_endian_bytes() {
        let value = U24::from_be_bytes([0x12, 0x34, 0x56]);
        assert_eq!(value.to_usize(), 0x12_3456);
        assert_eq!(value.to_be_bytes(), [0x12, 0x34, 0x56]);
    }
}
