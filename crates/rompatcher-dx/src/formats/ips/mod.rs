//! The International Patching System (IPS) patch format.

mod codec;
mod operations;

pub use codec::Error;
pub use operations::{apply, create};
