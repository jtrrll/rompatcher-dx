//! A ROM patching library.

#![forbid(unsafe_code)]

use core::fmt;

pub mod formats;
pub use formats::ips;
mod u24;

/// The patch formats supported by rompatcher-dx.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PatchFormat {
    /// The International Patching System format.
    Ips,
}

/// A reason a patch cannot be applied or created.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[non_exhaustive]
pub enum Error {
    /// An IPS patch cannot be applied or created.
    Ips(ips::Error),
}

impl fmt::Display for Error {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Ips(error) => write!(formatter, "IPS: {error}"),
        }
    }
}

impl core::error::Error for Error {}

/// Applies a patch in `format` to `rom`.
fn apply_patch(rom: &[u8], format: PatchFormat, patch: &[u8]) -> Result<Vec<u8>, Error> {
    match format {
        PatchFormat::Ips => match ips::apply(rom, patch) {
            Ok(patched_rom) => Ok(patched_rom),
            Err(error) => Err(Error::Ips(error)),
        },
    }
}

/// Applies the patches to `rom` in order, decoding each patch in the format it is paired with.
///
/// # Errors
///
/// Returns the error of the first patch that cannot be applied.
#[expect(
    clippy::needless_range_loop,
    reason = "Aeneas does not model slice iterators"
)]
pub fn apply_patches(rom: &[u8], patches: &[(PatchFormat, Vec<u8>)]) -> Result<Vec<u8>, Error> {
    let mut patched_rom = rom.to_vec();
    for index in 0..patches.len() {
        let (format, patch) = &patches[index];
        patched_rom = apply_patch(&patched_rom, *format, patch)?;
    }
    Ok(patched_rom)
}

/// Creates a patch in `format` that transforms `unpatched_rom` into `patched_rom`.
///
/// # Errors
///
/// Returns an error if `format` cannot express the difference between the ROMs.
pub fn create_patch(
    unpatched_rom: &[u8],
    patched_rom: &[u8],
    format: PatchFormat,
) -> Result<Vec<u8>, Error> {
    match format {
        PatchFormat::Ips => match ips::create(unpatched_rom, patched_rom) {
            Ok(patch) => Ok(patch),
            Err(error) => Err(Error::Ips(error)),
        },
    }
}
