import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROMPATCHER_DX = os.environ["rompatcherDx"]
ROMPATCHER_JS = os.environ["rompatcherJs"]
FORMATS = ("ips", "bps", "ppf", "ups", "aps", "rup", "ebp")
UNPATCHED = bytes((index * 73 + 19) % 256 for index in range(128))
PATCHED = bytearray(UNPATCHED)
PATCHED[25:31] = b"patch!"
PATCHED[99] = 0
PATCHED = bytes(PATCHED)


def run_cli(executable, args, directory):
    return subprocess.run(
        [executable, *args],
        cwd=directory,
        capture_output=True,
        check=False,
    )


class ParityTest(unittest.TestCase):
    def reference_files(self, directory, patch_format):
        unpatched = directory / "unpatched.rom"
        patched = directory / "patched.rom"
        unpatched.write_bytes(UNPATCHED)
        patched.write_bytes(PATCHED)

        created = run_cli(
            ROMPATCHER_JS,
            ["create", unpatched.name, patched.name, "--format", patch_format],
            directory,
        )
        self.assertEqual(created.returncode, 0, created.stderr.decode(errors="replace"))

        extension = "ips" if patch_format == "ebp" else patch_format
        patch = directory / f"patched.{extension}"
        self.assertTrue(patch.is_file(), f"rompatcher-js did not create {patch_format} patch")
        self.assertTrue(patch.read_bytes(), f"rompatcher-js created an empty {patch_format} patch")

        applied = run_cli(ROMPATCHER_JS, ["patch", unpatched.name, patch.name], directory)
        self.assertEqual(applied.returncode, 0, applied.stderr.decode(errors="replace"))
        reference_rom = directory / "unpatched (patched).rom"
        self.assertTrue(reference_rom.is_file(), f"rompatcher-js did not apply {patch_format} patch")
        self.assertEqual(reference_rom.read_bytes(), PATCHED)
        return patch

    def assert_matches(self, result, expected, output_file):
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
        self.assertTrue(output_file.is_file(), f"Missing output file: {output_file}")
        self.assertEqual(output_file.read_bytes(), expected)

    def test_apply_patch(self):
        for patch_format in FORMATS:
            with self.subTest(format=patch_format):
                with tempfile.TemporaryDirectory() as temporary:
                    directory = Path(temporary)
                    patch = self.reference_files(directory, patch_format)

                    output = directory / "actual.rom"
                    result = run_cli(
                        ROMPATCHER_DX,
                        ["apply", "--input", "unpatched.rom", "--output", output.name, patch.name],
                        directory,
                    )
                    self.assert_matches(result, PATCHED, output)

    def test_create(self):
        for patch_format in FORMATS:
            with self.subTest(format=patch_format):
                with tempfile.TemporaryDirectory() as temporary:
                    directory = Path(temporary)
                    patch = self.reference_files(directory, patch_format)
                    expected = patch.read_bytes()

                    output = directory / "actual.patch"
                    result = run_cli(
                        ROMPATCHER_DX,
                        [
                            "create", "unpatched.rom", "--patched-rom", "patched.rom",
                            "--format", patch_format, "--output", output.name,
                        ],
                        directory,
                    )
                    self.assert_matches(result, expected, output)


if __name__ == "__main__":
    unittest.main()
