import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools import filter_ubsan

SHIFT_OVERFLOW_BLOCK = """../src/overflow.cpp:4:21: runtime error: shift exponent 32 is too large for 32-bit type 'unsigned int'
    #0 0x5612d124209a in main ../src/overflow.cpp:4
    #1 0x7fae8909fd4f (/usr/lib64/libc.so.6+0x23d4f)
    #2 0x7fae8909fe08 in __libc_start_main (/usr/lib64/libc.so.6+0x23e08)

SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior ../src/overflow.cpp:4:21 in main
"""

SIGNED_OVERFLOW_BLOCK = """../src/signed.cpp:10:5: runtime error: signed integer overflow: 2147483647 + 1 cannot be represented in type 'int'
    #0 0x5612d1242200 in compute() ../src/signed.cpp:10

SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior ../src/signed.cpp:10:5 in compute()
"""


def lines_of(block: str):
    return block.splitlines(keepends=True)


class ToJsonTests(unittest.TestCase):
    def test_parses_warning_and_summary(self):
        result = filter_ubsan.to_json(lines_of(SHIFT_OVERFLOW_BLOCK))

        self.assertIn("runtime error: shift exponent", result["warning"])
        self.assertIn("SUMMARY: UndefinedBehaviorSanitizer:", result["summary"])

    def test_single_implicit_stack_holds_all_frames(self):
        result = filter_ubsan.to_json(lines_of(SHIFT_OVERFLOW_BLOCK))

        self.assertEqual(len(result["stacks"]), 1)
        self.assertEqual(len(result["stacks"][0]["frames"]), 3)
        # No explicit stack header exists for UBSan, so the runtime error
        # line itself is reused as the (only) stack's header.
        self.assertIn("runtime error", result["stacks"][0]["header"])

    def test_parses_frames_with_and_without_filename(self):
        result = filter_ubsan.to_json(lines_of(SHIFT_OVERFLOW_BLOCK))

        frames = result["stacks"][0]["frames"]
        self.assertEqual(
            frames[0],
            {"depth": "#0", "f": "main", "filename": "../src/overflow.cpp", "linenumber": "4"},
        )
        self.assertIsNone(frames[1]["filename"])


class MainEndToEndTests(unittest.TestCase):
    def run_cli(self, *extra_args):
        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "ubsan.log"
            log_path.write_text(SHIFT_OVERFLOW_BLOCK + "\n" + SIGNED_OVERFLOW_BLOCK, encoding="utf-8")

            return subprocess.run(
                [sys.executable, str(Path(filter_ubsan.__file__)), "--filename", str(log_path), *extra_args],
                capture_output=True,
                text=True,
                check=True,
            )

    def test_plain_output_contains_both_reports_by_default(self):
        result = self.run_cli()

        self.assertIn("shift exponent", result.stdout)
        self.assertIn("signed integer overflow", result.stdout)

    def test_keep_containing_only_keeps_matching_report(self):
        result = self.run_cli("--keep-containing", "compute")

        self.assertNotIn("shift exponent", result.stdout)
        self.assertIn("signed integer overflow", result.stdout)

    def test_as_json_produces_two_reports(self):
        result = self.run_cli("--as-json")

        reports = json.loads(result.stdout)
        self.assertEqual(len(reports), 2)
        for report in reports:
            self.assertEqual(len(report["stacks"]), 1)


if __name__ == "__main__":
    unittest.main()
