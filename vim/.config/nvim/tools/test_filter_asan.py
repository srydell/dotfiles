import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools import filter_asan

HEAP_OVERFLOW_BLOCK = """=================================================================
==6226==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x603e0001fdf4 at pc 0x417f8c bp 0x7fff64c0c010 sp 0x7fff64c0c008
READ of size 4 at 0x603e0001fdf4 thread T0
    #0 0x417f8b in main ../src/example_heap.cpp:5
    #1 0x7fa97c09376c (/lib/x86_64-linux-gnu/libc.so.6+0x2176c)

0x603e0001fdf4 is located 4 bytes to the right of 400-byte region [0x603e0001fc60,0x603e0001fdf0)
allocated by thread T0 here:
    #0 0x40d312 in operator new[](unsigned long) /home/user/asan_new_delete.cc:46
    #1 0x417f1c in main ../src/example_heap.cpp:3

SUMMARY: AddressSanitizer: heap-buffer-overflow ../src/example_heap.cpp:5 in main
"""

USE_AFTER_FREE_BLOCK = """=================================================================
==6227==ERROR: AddressSanitizer: heap-use-after-free on address 0x603e0001fdf0
WRITE of size 4 at 0x603e0001fdf0 thread T1
    #0 0x417f8b in bar_thread_run() ../src/example_uaf.cpp:9

freed by thread T1 here:
    #0 0x40d312 in operator delete(void*) /home/user/asan_new_delete.cc:80

SUMMARY: AddressSanitizer: heap-use-after-free ../src/example_uaf.cpp:9 in bar_thread_run()
"""


def lines_of(block: str):
    return block.splitlines(keepends=True)


class ToJsonTests(unittest.TestCase):
    def test_parses_warning_and_summary(self):
        result = filter_asan.to_json(lines_of(HEAP_OVERFLOW_BLOCK))

        self.assertIn("ERROR: AddressSanitizer: heap-buffer-overflow", result["warning"])
        self.assertIn("SUMMARY: AddressSanitizer: heap-buffer-overflow", result["summary"])

    def test_parses_the_read_stack_and_the_allocation_stack(self):
        result = filter_asan.to_json(lines_of(HEAP_OVERFLOW_BLOCK))

        self.assertEqual(len(result["stacks"]), 2)
        self.assertTrue(result["stacks"][0]["header"].startswith("READ of size 4"))
        self.assertEqual(result["stacks"][0]["thread"], "T0")
        self.assertTrue(result["stacks"][1]["header"].startswith("allocated by thread T0"))

    def test_parses_frames_with_filename_and_linenumber(self):
        result = filter_asan.to_json(lines_of(HEAP_OVERFLOW_BLOCK))

        frame = result["stacks"][0]["frames"][0]
        self.assertEqual(frame, {"depth": "#0", "f": "main", "filename": "../src/example_heap.cpp", "linenumber": "5"})

    def test_parses_library_frames_without_filename(self):
        result = filter_asan.to_json(lines_of(HEAP_OVERFLOW_BLOCK))

        frame = result["stacks"][0]["frames"][1]
        self.assertEqual(frame["depth"], "#1")
        self.assertIsNone(frame["filename"])
        self.assertIn("libc.so.6", frame["f"])

    def test_registers_thread_names_from_headers(self):
        result = filter_asan.to_json(lines_of(USE_AFTER_FREE_BLOCK))

        self.assertEqual(result["thread_names"], {"T1": "T1"})
        self.assertEqual(result["stacks"][1]["thread"], "T1")


class MainEndToEndTests(unittest.TestCase):
    def run_cli(self, *extra_args):
        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "asan.log"
            log_path.write_text(HEAP_OVERFLOW_BLOCK + "\n" + USE_AFTER_FREE_BLOCK, encoding="utf-8")

            return subprocess.run(
                [sys.executable, str(Path(filter_asan.__file__)), "--filename", str(log_path), *extra_args],
                capture_output=True,
                text=True,
                check=True,
            )

    def test_plain_output_contains_both_reports_by_default(self):
        result = self.run_cli()

        self.assertIn("heap-buffer-overflow", result.stdout)
        self.assertIn("heap-use-after-free", result.stdout)

    def test_keep_containing_only_keeps_matching_report(self):
        result = self.run_cli("--keep-containing", "bar_thread_run")

        self.assertNotIn("heap-buffer-overflow", result.stdout)
        self.assertIn("heap-use-after-free", result.stdout)

    def test_as_json_produces_two_reports(self):
        result = self.run_cli("--as-json")

        reports = json.loads(result.stdout)
        self.assertEqual(len(reports), 2)
        for report in reports:
            self.assertIn("warning", report)
            self.assertIn("summary", report)
            self.assertIn("stacks", report)


if __name__ == "__main__":
    unittest.main()
