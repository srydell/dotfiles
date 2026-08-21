import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools import filter_lsan

LEAK_BLOCK = """=================================================================
==1234==ERROR: LeakSanitizer: detected memory leaks

Direct leak of 7 byte(s) in 1 object(s) allocated from:
    #0 0x4af0ad in malloc
    #1 0x4ea6e4 in main ../src/leak.cpp:4

Indirect leak of 16 byte(s) in 1 object(s) allocated from:
    #0 0x4af0ad in operator new(unsigned long)
    #1 0x4ea700 in make_node() ../src/leak.cpp:2

SUMMARY: LeakSanitizer: 7 byte(s) leaked in 1 allocation(s).
"""


def lines_of(block: str):
    return block.splitlines(keepends=True)


class ToJsonTests(unittest.TestCase):
    def test_parses_warning_and_summary(self):
        result = filter_lsan.to_json(lines_of(LEAK_BLOCK))

        self.assertIn("ERROR: LeakSanitizer: detected memory leaks", result["warning"])
        self.assertIn("SUMMARY: LeakSanitizer:", result["summary"])

    def test_parses_direct_and_indirect_leak_stacks(self):
        result = filter_lsan.to_json(lines_of(LEAK_BLOCK))

        self.assertEqual(len(result["stacks"]), 2)
        self.assertTrue(result["stacks"][0]["header"].startswith("Direct leak of"))
        self.assertTrue(result["stacks"][1]["header"].startswith("Indirect leak of"))

    def test_leak_stacks_have_no_thread(self):
        result = filter_lsan.to_json(lines_of(LEAK_BLOCK))

        self.assertIsNone(result["stacks"][0]["thread"])
        self.assertEqual(result["thread_names"], {})

    def test_parses_frames_with_and_without_filename(self):
        result = filter_lsan.to_json(lines_of(LEAK_BLOCK))

        frames = result["stacks"][0]["frames"]
        self.assertEqual(frames[0], {"depth": "#0", "f": "malloc", "filename": None, "linenumber": None})
        self.assertEqual(
            frames[1],
            {"depth": "#1", "f": "main", "filename": "../src/leak.cpp", "linenumber": "4"},
        )


class MainEndToEndTests(unittest.TestCase):
    def run_cli(self, *extra_args):
        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "lsan.log"
            log_path.write_text(LEAK_BLOCK, encoding="utf-8")

            return subprocess.run(
                [sys.executable, str(Path(filter_lsan.__file__)), "--filename", str(log_path), *extra_args],
                capture_output=True,
                text=True,
                check=True,
            )

    def test_plain_output_contains_the_report(self):
        result = self.run_cli()

        self.assertIn("detected memory leaks", result.stdout)

    def test_remove_containing_drops_the_only_report(self):
        result = self.run_cli("--remove-containing", "make_node")

        self.assertEqual(result.stdout.strip(), "")

    def test_as_json_produces_one_report_with_both_stacks(self):
        result = self.run_cli("--as-json")

        reports = json.loads(result.stdout)
        self.assertEqual(len(reports), 1)
        self.assertEqual(len(reports[0]["stacks"]), 2)


if __name__ == "__main__":
    unittest.main()
