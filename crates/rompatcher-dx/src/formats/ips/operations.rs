//! Applying and creating IPS patches.

use super::codec::{
    END_MARKER_OFFSET, Error, MAX_PAYLOAD_SIZE, PatchContents, PatchRecord, decode, encode,
};
use crate::u24::U24;

/// The largest offset an IPS patch record can start at.
const MAX_OFFSET: usize = 0xFF_FFFF;

/// Grows `rom` with zero bytes to at least `size` bytes.
fn grow(rom: &mut Vec<u8>, size: usize) {
    if rom.len() < size {
        rom.resize(size, 0);
    }
}

/// Applies one IPS patch record to `rom`, first growing `rom` with zero bytes if the record does
/// not fit.
fn apply_record(rom: &mut Vec<u8>, record: &PatchRecord) {
    match record {
        PatchRecord::Regular { offset, payload } => {
            let start = offset.to_usize();
            let end = start + payload.len();
            grow(rom, end);
            rom[start..end].copy_from_slice(payload);
        }
        PatchRecord::RunLengthEncoded {
            offset,
            run_length,
            value,
        } => {
            let start = offset.to_usize();
            let end = start + *run_length as usize;
            grow(rom, end);
            rom[start..end].fill(*value);
        }
    }
}

/// Applies an IPS patch to a ROM.
///
/// # Errors
///
/// Returns an error if `patch` is not a well-formed IPS patch.
pub fn apply(rom: &[u8], patch: &[u8]) -> Result<Vec<u8>, Error> {
    let contents = decode(patch)?;
    let mut patched_rom = rom.to_vec();
    for index in 0..contents.records.len() {
        apply_record(&mut patched_rom, &contents.records[index]);
    }
    if let Some(final_size) = contents.final_size {
        patched_rom.resize(final_size.to_usize(), 0);
    }
    Ok(patched_rom)
}

/// Whether a record must write `patched`'s byte at `pos`, either because `unpatched` has a
/// different byte there or because a ROM grown to the size of `patched` would have a different
/// padding byte there. The last byte of a grown ROM is always written, so that `apply` grows the
/// ROM to the full size. `pos` must be less than the size of `patched`.
const fn must_write(unpatched: &[u8], patched: &[u8], pos: usize) -> bool {
    let is_last_byte = pos + 1 == patched.len();
    if pos < unpatched.len() {
        unpatched[pos] != patched[pos]
    } else {
        patched[pos] != 0 || is_last_byte
    }
}

/// Finds the end of the run of bytes that must be written, starting at `pos` and stopping at
/// `limit`.
const fn run_end(unpatched: &[u8], patched: &[u8], pos: usize, limit: usize) -> usize {
    let mut end = pos;
    while end < limit && must_write(unpatched, patched, end) {
        end += 1;
    }
    end
}

/// Picks the offset of a record that writes the byte at `pos`: `pos` itself when IPS can encode
/// it, otherwise the closest earlier offset that it can encode.
#[expect(
    clippy::question_mark,
    reason = "Aeneas does not model the `?` operator on `Option`"
)]
fn record_start(pos: usize) -> Option<U24> {
    let Some(offset) = U24::from_usize(pos.min(MAX_OFFSET)) else {
        return None;
    };
    if offset == END_MARKER_OFFSET {
        U24::from_usize(offset.to_usize() - 1)
    } else {
        Some(offset)
    }
}

/// The position a record starting at `start` must end at or before: IPS payloads hold at most
/// 65535 bytes, and records never extend past the end of `patched`.
fn record_limit(patched: &[u8], start: U24) -> usize {
    patched.len().min(start.to_usize() + MAX_PAYLOAD_SIZE)
}

/// Creates regular records that write every byte of `patched` that must be written.
fn create_records(unpatched: &[u8], patched: &[u8]) -> Result<Vec<PatchRecord>, Error> {
    let mut records = Vec::new();
    let mut pos = 0;
    while pos < patched.len() {
        if must_write(unpatched, patched, pos) {
            let Some(start) = record_start(pos) else {
                return Err(Error::DifferenceBeyondOffsetLimit);
            };
            let limit = record_limit(patched, start);
            if limit <= pos {
                return Err(Error::DifferenceBeyondOffsetLimit);
            }
            let end = run_end(unpatched, patched, pos + 1, limit);
            let payload = patched[start.to_usize()..end].to_vec();
            records.push(PatchRecord::Regular {
                offset: start,
                payload,
            });
            pos = end;
        } else {
            pos += 1;
        }
    }
    Ok(records)
}

/// Creates an IPS patch from two ROMs.
///
/// # Errors
///
/// Returns an error if IPS cannot express the difference between the ROMs.
pub fn create(unpatched: &[u8], patched: &[u8]) -> Result<Vec<u8>, Error> {
    let final_size = if patched.len() < unpatched.len() {
        let Some(size) = U24::from_usize(patched.len()) else {
            return Err(Error::PatchedRomTooLargeToShrink);
        };
        Some(size)
    } else {
        None
    };
    let records = create_records(unpatched, patched)?;
    encode(&PatchContents {
        records,
        final_size,
    })
}

#[cfg(test)]
mod tests {
    use super::{Error, apply, create};

    #[test]
    fn applies_regular_and_rle_records() {
        let patch = b"PATCH\x00\x00\x01\x00\x02ab\x00\x00\x05\x00\x00\x00\x03zEOF";
        assert_eq!(apply(b"0123", patch), Ok(b"0ab3\0zzz".to_vec()));
    }

    #[test]
    fn truncates_to_the_final_size() {
        assert_eq!(apply(b"0123", b"PATCHEOF\x00\x00\x00"), Ok(Vec::new()));
    }

    #[test]
    fn rejects_a_missing_header() {
        assert_eq!(apply(b"0123", b"PATC"), Err(Error::MissingHeader));
    }

    #[test]
    fn rejects_data_after_the_end_marker() {
        assert_eq!(
            apply(b"0123", b"PATCHEOF\x00"),
            Err(Error::UnexpectedDataAfterEndMarker)
        );
    }

    #[test]
    fn creates_patches_that_apply_to_the_patched_rom() {
        let unpatched: Vec<u8> = (0..200_u8).collect();
        let mut patched = unpatched.clone();
        patched[10..14].copy_from_slice(b"ips!");
        patched.truncate(150);
        let patch = create(&unpatched, &patched).unwrap();
        assert_eq!(apply(&unpatched, &patch), Ok(patched));
    }

    #[test]
    fn grows_the_rom_to_the_last_byte() {
        let unpatched = b"0123".to_vec();
        let patched = b"0123\0\0\0".to_vec();
        let patch = create(&unpatched, &patched).unwrap();
        assert_eq!(apply(&unpatched, &patch), Ok(patched));
    }
}
