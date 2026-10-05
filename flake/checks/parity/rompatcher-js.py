import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROMPATCHER_DX = os.environ["rompatcherDX"]
ROMPATCHER_JS = os.environ["rompatcherJs"]
FORMATS = ("ips",)
UNPATCHED = bytes((index * 73 + 19) % 256 for index in range(128))
PATCHED = bytearray(UNPATCHED)
PATCHED[25:31] = b"patch!"
PATCHED[99] = 0
PATCHED = bytes(PATCHED)


def run(executable: str, *args: str, cwd: Path) -> None:
    """Runs a command-line program, failing the test with its error output if it fails."""
    result = subprocess.run([executable, *args], cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(
            f"{Path(executable).name} {' '.join(args)} exited with {result.returncode}:\n"
            f"{result.stderr}"
        )


def rompatcher_dx_apply(rom: Path, patch: Path) -> bytes:
    """Applies `patch` to `rom` with rompatcher-dx and returns the patched ROM."""
    output = rom.with_name(f"{rom.stem} (rompatcher-dx){rom.suffix}")
    run(ROMPATCHER_DX, "apply", "--input", rom.name, "--output", output.name, patch.name, cwd=rom.parent)
    return output.read_bytes()


def rompatcher_dx_create(unpatched: Path, patched: Path, patch_format: str) -> Path:
    """Creates a patch from `unpatched` to `patched` with rompatcher-dx and returns its path."""
    patch = patched.with_name(f"{patched.stem} (rompatcher-dx).{patch_format}")
    run(
        ROMPATCHER_DX,
        "create", unpatched.name,
        "--patched-rom", patched.name,
        "--format", patch_format,
        "--output", patch.name,
        cwd=unpatched.parent,
    )
    return patch


def rompatcher_js_apply(rom: Path, patch: Path) -> bytes:
    """Applies `patch` to `rom` with rompatcher-js and returns the patched ROM."""
    run(ROMPATCHER_JS, "patch", rom.name, patch.name, cwd=rom.parent)
    return rom.with_name(f"{rom.stem} (patched){rom.suffix}").read_bytes()


def rompatcher_js_create(unpatched: Path, patched: Path, patch_format: str) -> Path:
    """Creates a patch from `unpatched` to `patched` with rompatcher-js and returns its path."""
    run(ROMPATCHER_JS, "create", unpatched.name, patched.name, "--format", patch_format, cwd=unpatched.parent)
    return patched.with_suffix(f".{patch_format}")


class ParityTest(unittest.TestCase):
    def write_roms(self) -> tuple[Path, Path]:
        """Writes the unpatched and patched ROMs to a new temporary directory."""
        directory = Path(self.enterContext(tempfile.TemporaryDirectory()))
        unpatched = directory / "unpatched.rom"
        patched = directory / "patched.rom"
        unpatched.write_bytes(UNPATCHED)
        patched.write_bytes(PATCHED)
        return unpatched, patched

    def test_apply(self) -> None:
        for patch_format in FORMATS:
            with self.subTest(format=patch_format):
                unpatched, patched = self.write_roms()
                patch = rompatcher_js_create(unpatched, patched, patch_format)
                self.assertEqual(
                    rompatcher_dx_apply(unpatched, patch), rompatcher_js_apply(unpatched, patch)
                )

    def test_create(self) -> None:
        for patch_format in FORMATS:
            with self.subTest(format=patch_format):
                unpatched, patched = self.write_roms()
                rompatcher_dx_patch = rompatcher_dx_create(unpatched, patched, patch_format)
                rompatcher_js_patch = rompatcher_js_create(unpatched, patched, patch_format)
                self.assertEqual(rompatcher_dx_patch.read_bytes(), rompatcher_js_patch.read_bytes())


if __name__ == "__main__":
    unittest.main()
