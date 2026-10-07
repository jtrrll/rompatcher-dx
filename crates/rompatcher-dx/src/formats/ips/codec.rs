//! IPS patch structure, encoding, and decoding.

use core::fmt;

use crate::u24::U24;

/// The magic header identifying an IPS patch.
const HEADER: [u8; 5] = *b"PATCH";

/// The marker ending the sequence of IPS patch records.
const END_MARKER: [u8; 3] = *b"EOF";

/// The record offset whose encoding is the end marker.
pub(super) const END_MARKER_OFFSET: U24 = U24::from_be_bytes(END_MARKER);

/// The largest number of bytes a regular IPS patch record can write.
pub(super) const MAX_PAYLOAD_SIZE: usize = 0xFFFF;

/// A reason an IPS patch cannot be applied or created.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[non_exhaustive]
pub enum Error {
    /// The patch does not start with the `PATCH` header.
    MissingHeader,
    /// The patch ends before the `EOF` marker.
    MissingEndMarker,
    /// The `EOF` marker is followed by something other than a three-byte final size.
    UnexpectedDataAfterEndMarker,
    /// The patch ends inside a patch record offset.
    TruncatedRecordOffset,
    /// The patch ends inside a patch record length.
    TruncatedRecordLength,
    /// The patch ends inside an RLE patch record.
    TruncatedRleRecord,
    /// The patch ends inside the payload of a regular patch record.
    TruncatedRegularRecord,
    /// A regular patch record payload is empty or longer than 65535 bytes.
    InvalidPayloadSize,
    /// A patch record starts at the offset whose encoding is the `EOF` marker.
    ReservedRecordOffset,
    /// The patched ROM is smaller than the unpatched ROM and too large for the final-size trailer.
    PatchedRomTooLargeToShrink,
    /// The ROMs differ at a byte that no patch record can reach.
    DifferenceBeyondOffsetLimit,
}

impl fmt::Display for Error {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let message = match self {
            Self::MissingHeader => "missing PATCH header",
            Self::MissingEndMarker => "missing EOF marker",
            Self::UnexpectedDataAfterEndMarker => "unexpected data after EOF marker",
            Self::TruncatedRecordOffset => "truncated record offset",
            Self::TruncatedRecordLength => "truncated record length",
            Self::TruncatedRleRecord => "truncated RLE record",
            Self::TruncatedRegularRecord => "truncated regular record",
            Self::InvalidPayloadSize => "regular record payload must be 1 to 65535 bytes",
            Self::ReservedRecordOffset => "record offset is reserved for the EOF marker",
            Self::PatchedRomTooLargeToShrink => "cannot shrink a ROM to 16 MiB or more",
            Self::DifferenceBeyondOffsetLimit => "ROMs differ beyond the IPS offset limit",
        };
        formatter.write_str(message)
    }
}

impl core::error::Error for Error {}

/// An IPS patch record writes a regular payload or repeats one byte.
pub(super) enum PatchRecord {
    /// Writes `payload` at `offset`.
    Regular {
        /// The ROM offset of the first written byte.
        offset: U24,
        /// The bytes to write.
        payload: Vec<u8>,
    },
    /// Writes `value` `run_length` times at `offset`.
    RunLengthEncoded {
        /// The ROM offset of the first written byte.
        offset: U24,
        /// The number of times to write `value`.
        run_length: u16,
        /// The byte to write.
        value: u8,
    },
}

impl PatchRecord {
    /// The ROM offset of the first byte the record writes.
    pub(super) const fn offset(&self) -> U24 {
        match self {
            Self::Regular { offset, .. } | Self::RunLengthEncoded { offset, .. } => *offset,
        }
    }
}

/// The contents of an IPS patch.
pub(super) struct PatchContents {
    /// The patch records, in the order they are applied.
    pub(super) records: Vec<PatchRecord>,
    /// The exact size of the patched ROM, stored in an optional trailer after the end marker.
    pub(super) final_size: Option<U24>,
}

/// The next item of an IPS patch after the header: a patch record or the end marker.
enum DecodedItem {
    /// A patch record, followed by the item at `next_pos`.
    Record {
        /// The decoded patch record.
        record: PatchRecord,
        /// The position of the item after the patch record.
        next_pos: usize,
    },
    /// The end marker, followed by the optional final-size trailer.
    End {
        /// The final size stored in the trailer, if there is one.
        final_size: Option<U24>,
    },
}

/// Reads the unsigned two-byte big-endian number stored at `pos`, if those bytes exist.
const fn read_u16(bytes: &[u8], pos: usize) -> Option<u16> {
    let has_two_bytes = bytes.len() >= 2 && pos <= bytes.len() - 2;
    if !has_two_bytes {
        return None;
    }
    let high = bytes[pos] as u16;
    let low = bytes[pos + 1] as u16;
    Some((high << 8) | low)
}

/// Reads the unsigned three-byte big-endian number stored at `pos`, if those bytes exist.
const fn read_u24(bytes: &[u8], pos: usize) -> Option<U24> {
    let has_three_bytes = bytes.len() >= 3 && pos <= bytes.len() - 3;
    if !has_three_bytes {
        return None;
    }
    Some(U24::from_be_bytes([
        bytes[pos],
        bytes[pos + 1],
        bytes[pos + 2],
    ]))
}

/// Appends `value` as an unsigned two-byte big-endian number.
#[expect(
    clippy::cast_possible_truncation,
    reason = "each cast keeps exactly one byte"
)]
fn write_u16(bytes: &mut Vec<u8>, value: u16) {
    bytes.push((value >> 8) as u8);
    bytes.push(value as u8);
}

/// Whether `bytes` holds `expected` at `pos`.
fn matches_at(bytes: &[u8], pos: usize, expected: &[u8]) -> bool {
    let has_room = bytes.len() >= expected.len() && pos <= bytes.len() - expected.len();
    if !has_room {
        return false;
    }
    for index in 0..expected.len() {
        if bytes[pos + index] != expected[index] {
            return false;
        }
    }
    true
}

/// Decodes the patch record or end marker that starts at `pos`.
fn decode_item(patch: &[u8], pos: usize) -> Result<DecodedItem, Error> {
    if patch.len() <= pos {
        return Err(Error::MissingEndMarker);
    }
    if matches_at(patch, pos, &END_MARKER) {
        let final_size = decode_final_size(patch, pos + END_MARKER.len())?;
        return Ok(DecodedItem::End { final_size });
    }
    let Some(offset) = read_u24(patch, pos) else {
        return Err(Error::TruncatedRecordOffset);
    };
    let Some(length) = read_u16(patch, pos + 3) else {
        return Err(Error::TruncatedRecordLength);
    };
    let is_rle_record = length == 0;
    if is_rle_record {
        let Some(run_length) = read_u16(patch, pos + 5) else {
            return Err(Error::TruncatedRleRecord);
        };
        let value_pos = pos + 7;
        if value_pos >= patch.len() {
            return Err(Error::TruncatedRleRecord);
        }
        let record = PatchRecord::RunLengthEncoded {
            offset,
            run_length,
            value: patch[value_pos],
        };
        return Ok(DecodedItem::Record {
            record,
            next_pos: value_pos + 1,
        });
    }
    let payload_start = pos + 5;
    let payload_end = payload_start + length as usize;
    if payload_end > patch.len() {
        return Err(Error::TruncatedRegularRecord);
    }
    let payload = patch[payload_start..payload_end].to_vec();
    Ok(DecodedItem::Record {
        record: PatchRecord::Regular { offset, payload },
        next_pos: payload_end,
    })
}

/// Decodes the optional final-size trailer that starts at `pos`, right after the end marker.
const fn decode_final_size(patch: &[u8], pos: usize) -> Result<Option<U24>, Error> {
    if pos == patch.len() {
        return Ok(None);
    }
    let Some(final_size) = read_u24(patch, pos) else {
        return Err(Error::UnexpectedDataAfterEndMarker);
    };
    if pos + 3 != patch.len() {
        return Err(Error::UnexpectedDataAfterEndMarker);
    }
    Ok(Some(final_size))
}

/// Decodes the contents of an IPS patch.
pub(super) fn decode(patch: &[u8]) -> Result<PatchContents, Error> {
    if !matches_at(patch, 0, &HEADER) {
        return Err(Error::MissingHeader);
    }
    let mut records = Vec::new();
    let mut pos = HEADER.len();
    loop {
        match decode_item(patch, pos)? {
            DecodedItem::Record { record, next_pos } => {
                records.push(record);
                pos = next_pos;
            }
            DecodedItem::End { final_size } => {
                return Ok(PatchContents {
                    records,
                    final_size,
                });
            }
        }
    }
}

/// Appends the length and payload of a regular IPS patch record to `bytes`.
#[expect(
    clippy::cast_possible_truncation,
    reason = "the payload size check guarantees that the cast is lossless"
)]
fn encode_regular_record(bytes: &mut Vec<u8>, payload: &[u8]) -> Result<(), Error> {
    let payload_size_fits = payload.len() <= MAX_PAYLOAD_SIZE && !payload.is_empty();
    if !payload_size_fits {
        return Err(Error::InvalidPayloadSize);
    }
    write_u16(bytes, payload.len() as u16);
    bytes.extend_from_slice(payload);
    Ok(())
}

/// Encodes one IPS patch record.
fn encode_record(record: &PatchRecord) -> Result<Vec<u8>, Error> {
    let offset = record.offset();
    if offset == END_MARKER_OFFSET {
        return Err(Error::ReservedRecordOffset);
    }
    let mut bytes = offset.to_be_bytes().to_vec();
    match record {
        PatchRecord::Regular { payload, .. } => encode_regular_record(&mut bytes, payload)?,
        PatchRecord::RunLengthEncoded {
            run_length, value, ..
        } => {
            write_u16(&mut bytes, 0);
            write_u16(&mut bytes, *run_length);
            bytes.push(*value);
        }
    }
    Ok(bytes)
}

/// Encodes the contents of an IPS patch.
pub(super) fn encode(contents: &PatchContents) -> Result<Vec<u8>, Error> {
    let mut patch = HEADER.to_vec();
    for index in 0..contents.records.len() {
        let encoded_record = encode_record(&contents.records[index])?;
        patch.extend_from_slice(&encoded_record);
    }
    patch.extend_from_slice(&END_MARKER);
    if let Some(final_size) = contents.final_size {
        patch.extend_from_slice(&final_size.to_be_bytes());
    }
    Ok(patch)
}

#[cfg(test)]
mod tests {
    use super::read_u16;

    #[test]
    fn reads_big_endian_bytes() {
        assert_eq!(read_u16(&[0x12, 0x34, 0x56], 1), Some(0x3456));
    }

    #[test]
    fn rejects_missing_bytes() {
        assert_eq!(read_u16(&[0x12, 0x34], 1), None);
    }
}
