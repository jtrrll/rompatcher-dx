//! The rompatcher-dx command-line interface.

#![forbid(unsafe_code)]

use std::fs;
use std::io::{self, Read as _, Write as _};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use clap::{Parser, Subcommand};
use rompatcher_dx::PatchFormat;

/// A ROM patching library and CLI.
#[derive(Debug, Parser)]
#[command(name = "rompatcher-dx", version, arg_required_else_help = true)]
struct Cli {
    /// The subcommand to run.
    #[command(subcommand)]
    command: Command,
}

/// The rompatcher-dx subcommands.
#[derive(Debug, Subcommand)]
enum Command {
    /// Apply one or more patches to a ROM.
    Apply {
        /// Read the unpatched ROM from a file instead of stdin.
        #[arg(short, long)]
        input: Option<PathBuf>,
        /// Write the patched ROM to a file instead of stdout.
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// Patch files to apply in order, in the format given by each file's extension.
        #[arg(required = true)]
        patches: Vec<PathBuf>,
    },
    /// Create a patch from an unpatched ROM and a patched ROM.
    Create {
        /// File containing the unpatched ROM.
        unpatched_rom: PathBuf,
        /// Read the patched ROM from a file instead of stdin.
        #[arg(long)]
        patched_rom: Option<PathBuf>,
        /// Write the patch to a file instead of stdout.
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// Patch format to create.
        #[arg(short, long, value_parser = parse_format)]
        format: PatchFormat,
    },
}

impl Command {
    /// The name of the subcommand, as typed on the command line.
    const fn name(&self) -> &'static str {
        match self {
            Self::Apply { .. } => "apply",
            Self::Create { .. } => "create",
        }
    }

    /// Runs the subcommand.
    fn run(&self) -> Result<(), String> {
        match self {
            Self::Apply {
                input,
                output,
                patches,
            } => apply(input.as_deref(), output.as_deref(), patches),
            Self::Create {
                unpatched_rom,
                patched_rom,
                output,
                format,
            } => create(
                unpatched_rom,
                patched_rom.as_deref(),
                output.as_deref(),
                *format,
            ),
        }
    }
}

/// Parses a case-insensitive patch-format name, which is also the format's file extension.
fn format_from_name(name: &str) -> Option<PatchFormat> {
    if name.eq_ignore_ascii_case("ips") {
        Some(PatchFormat::Ips)
    } else {
        None
    }
}

/// Parses the patch format supplied to the create command.
fn parse_format(name: &str) -> Result<PatchFormat, String> {
    format_from_name(name).ok_or_else(|| format!("unsupported patch format: {name}"))
}

/// Reads binary input from `path`, or from standard input when no path is given.
fn read_input(path: Option<&Path>) -> io::Result<Vec<u8>> {
    if let Some(path) = path {
        return fs::read(path);
    }
    let mut bytes = Vec::new();
    io::stdin().read_to_end(&mut bytes)?;
    Ok(bytes)
}

/// Writes bytes to `path`, or to standard output when no path is given.
fn write_output(path: Option<&Path>, bytes: &[u8]) -> io::Result<()> {
    if let Some(path) = path {
        return fs::write(path, bytes);
    }
    let mut stdout = io::stdout().lock();
    stdout.write_all(bytes)?;
    stdout.flush()
}

/// Reads a file, naming it in the error message if it cannot be read.
fn read_file(path: &Path) -> Result<Vec<u8>, String> {
    fs::read(path).map_err(|error| format!("{}: {error}", path.display()))
}

/// Reads a patch file, identifying its format by its case-insensitive file extension.
fn read_patch(path: &Path) -> Result<(PatchFormat, Vec<u8>), String> {
    let format = path
        .extension()
        .and_then(|extension| extension.to_str())
        .and_then(format_from_name)
        .ok_or_else(|| format!("unrecognized patch file extension: {}", path.display()))?;
    Ok((format, read_file(path)?))
}

/// Reads and applies the requested patches, then writes the resulting ROM.
fn apply(
    input: Option<&Path>,
    output: Option<&Path>,
    patch_paths: &[PathBuf],
) -> Result<(), String> {
    let rom = read_input(input).map_err(|error| error.to_string())?;
    let patches = patch_paths
        .iter()
        .map(|path| read_patch(path))
        .collect::<Result<Vec<_>, _>>()?;
    let patched_rom =
        rompatcher_dx::apply_patches(&rom, &patches).map_err(|error| error.to_string())?;
    write_output(output, &patched_rom).map_err(|error| error.to_string())
}

/// Reads the unpatched and patched ROMs, then writes the created patch.
fn create(
    unpatched_rom: &Path,
    patched_rom: Option<&Path>,
    output: Option<&Path>,
    format: PatchFormat,
) -> Result<(), String> {
    let unpatched = read_file(unpatched_rom)?;
    let patched = read_input(patched_rom).map_err(|error| error.to_string())?;
    let patch = rompatcher_dx::create_patch(&unpatched, &patched, format)
        .map_err(|error| error.to_string())?;
    write_output(output, &patch).map_err(|error| error.to_string())
}

fn main() -> ExitCode {
    let command = Cli::parse().command;
    let Err(message) = command.run() else {
        return ExitCode::SUCCESS;
    };
    // Nothing else can report the failure if standard error is unwritable.
    let _ignored = writeln!(io::stderr(), "rompatcher-dx {}: {message}", command.name());
    ExitCode::FAILURE
}
