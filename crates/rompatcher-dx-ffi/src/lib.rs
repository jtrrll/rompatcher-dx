//! Foreign-language bindings to the rompatcher-dx library.

/// Types and operations available to foreign-language callers.
#[expect(
    clippy::unnecessary_box_returns,
    reason = "Diplomat represents opaque values as owned pointers across the FFI"
)]
#[diplomat::bridge]
mod ffi {
    use rompatcher_dx::{self as rust_api, PatchFormat as RustPatchFormat};

    /// A patch format supported by rompatcher-dx.
    pub enum PatchFormat {
        /// International Patching System.
        #[expect(dead_code, reason = "the variant is constructed by foreign callers")]
        Ips,
    }

    /// An error creating or applying an IPS patch.
    pub enum PatchError {
        /// The PATCH header is missing.
        MissingHeader,
        /// The EOF marker is missing.
        MissingEndMarker,
        /// Unexpected bytes follow the EOF marker.
        UnexpectedDataAfterEndMarker,
        /// The record offset is truncated.
        TruncatedRecordOffset,
        /// The record length is truncated.
        TruncatedRecordLength,
        /// The RLE record is truncated.
        TruncatedRleRecord,
        /// The regular record is truncated.
        TruncatedRegularRecord,
        /// The payload size is invalid.
        InvalidPayloadSize,
        /// The offset is reserved for the EOF marker.
        ReservedRecordOffset,
        /// The patched ROM is too large to shrink.
        PatchedRomTooLargeToShrink,
        /// A difference lies beyond the IPS offset limit.
        DifferenceBeyondOffsetLimit,
        /// An unrecognized error from a newer version of the core library.
        Unknown,
    }

    /// An owned result of applying patches or creating a patch.
    #[diplomat::opaque]
    pub struct Bytes(Vec<u8>);

    /// An ordered list of patches and their formats.
    #[diplomat::opaque_mut]
    pub struct PatchList(Vec<(RustPatchFormat, Vec<u8>)>);

    /// The rompatcher-dx patching operations.
    #[diplomat::opaque]
    pub struct RompatcherDX;

    impl From<rust_api::Error> for PatchError {
        fn from(error: rust_api::Error) -> Self {
            match error {
                rust_api::Error::Ips(error) => match error {
                    rust_api::ips::Error::MissingHeader => Self::MissingHeader,
                    rust_api::ips::Error::MissingEndMarker => Self::MissingEndMarker,
                    rust_api::ips::Error::UnexpectedDataAfterEndMarker => {
                        Self::UnexpectedDataAfterEndMarker
                    }
                    rust_api::ips::Error::TruncatedRecordOffset => Self::TruncatedRecordOffset,
                    rust_api::ips::Error::TruncatedRecordLength => Self::TruncatedRecordLength,
                    rust_api::ips::Error::TruncatedRleRecord => Self::TruncatedRleRecord,
                    rust_api::ips::Error::TruncatedRegularRecord => Self::TruncatedRegularRecord,
                    rust_api::ips::Error::InvalidPayloadSize => Self::InvalidPayloadSize,
                    rust_api::ips::Error::ReservedRecordOffset => Self::ReservedRecordOffset,
                    rust_api::ips::Error::PatchedRomTooLargeToShrink => {
                        Self::PatchedRomTooLargeToShrink
                    }
                    rust_api::ips::Error::DifferenceBeyondOffsetLimit => {
                        Self::DifferenceBeyondOffsetLimit
                    }
                    _ => Self::Unknown,
                },
                _ => Self::Unknown,
            }
        }
    }

    impl Bytes {
        /// Borrows the result bytes for as long as this object is alive.
        #[expect(
            clippy::needless_lifetimes,
            reason = "Diplomat requires the return slice lifetime to be explicit"
        )]
        pub fn as_slice<'buffer>(&'buffer self) -> &'buffer [u8] {
            &self.0
        }
    }

    impl PatchList {
        /// Creates an empty patch list.
        pub fn new() -> Box<Self> {
            Box::new(Self(Vec::new()))
        }

        /// Adds a patch in the given format, copying its bytes.
        pub fn add(&mut self, format: PatchFormat, patch: &[u8]) {
            let rust_format = match format {
                PatchFormat::Ips => RustPatchFormat::Ips,
            };
            self.0.push((rust_format, patch.to_vec()));
        }
    }

    impl RompatcherDX {
        /// Applies a list of patches to a ROM in order.
        ///
        /// # Errors
        ///
        /// Returns the error of the first patch that cannot be applied.
        pub fn apply_patches(rom: &[u8], patches: &PatchList) -> Result<Box<Bytes>, PatchError> {
            rust_api::apply_patches(rom, &patches.0)
                .map(|bytes| Box::new(Bytes(bytes)))
                .map_err(PatchError::from)
        }

        /// Creates a patch that transforms `unpatched_rom` into `patched_rom`.
        ///
        /// # Errors
        ///
        /// Returns an error if the format cannot express the difference.
        pub fn create_patch(
            unpatched_rom: &[u8],
            patched_rom: &[u8],
            format: PatchFormat,
        ) -> Result<Box<Bytes>, PatchError> {
            let rust_format = match format {
                PatchFormat::Ips => RustPatchFormat::Ips,
            };
            rust_api::create_patch(unpatched_rom, patched_rom, rust_format)
                .map(|bytes| Box::new(Bytes(bytes)))
                .map_err(PatchError::from)
        }
    }
}
