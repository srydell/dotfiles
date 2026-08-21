import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools import filter_tsan

DATA_RACE_BLOCK = """WARNING: ThreadSanitizer: data race (pid=12345)
  Write of size 4 at 0x7b0400000000 by thread T2 (mutexes: write M1):
    #0 foo_thread_run() ../src/foo_thread.cpp:42 (mybinary+0x455f8)
    #1 start_thread <null> (libpthread.so.0+0x76db)

  Previous read of size 4 at 0x7b0400000000 by main thread:
    #0 main() ../src/main.cpp:10 (mybinary+0x1234)

  Thread T2 'foo_thread' (tid=3164, running) created by main thread at:
    #0 pthread_create <null> (libtsan.so.0+0x2f783)
    #1 main() ../src/main.cpp:8 (mybinary+0x1111)

SUMMARY: ThreadSanitizer: data race ../src/foo_thread.cpp:42 in foo_thread_run()
"""

USE_AFTER_FREE_BLOCK = """WARNING: ThreadSanitizer: heap-use-after-free (pid=12346)
  Read of size 8 at 0x7b0400001000 by thread T3:
    #0 bar_thread_run() ../src/bar_thread.cpp:99 (mybinary+0x6789)

  Previous write of size 8 at 0x7b0400001000 by thread T4:
    #0 free_bar() ../src/bar_thread.cpp:88 (mybinary+0x5555)

  Location is heap block of size 64 at 0x7b0400001000 allocated by thread T4:
    #0 malloc <null> (libtsan.so.0+0x53a30)
    #1 alloc_bar() ../src/bar_thread.cpp:70 (mybinary+0x4444)

  Thread T3 (tid=3165, running) created by main thread at:
    [failed to restore the stack]

SUMMARY: ThreadSanitizer: heap-use-after-free ../src/bar_thread.cpp:99 in bar_thread_run()
"""


def lines_of(block: str):
    return block.splitlines(keepends=True)


class ToJsonTests(unittest.TestCase):
    def test_parses_warning_and_summary(self):
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        self.assertIn("WARNING: ThreadSanitizer: data race", result["warning"])
        self.assertIn("SUMMARY: ThreadSanitizer: data race", result["summary"])

    def test_parses_all_stacks_including_the_final_one(self):
        # Regression test: the last stack section in a warning (typically the
        # "Thread ... created by" section) must not be dropped just because
        # there is no subsequent stack header to trigger a flush.
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        self.assertEqual(len(result["stacks"]), 3)
        headers = [stack["header"] for stack in result["stacks"]]
        self.assertTrue(headers[0].startswith("Write of size 4"))
        self.assertTrue(headers[1].startswith("Previous read of size 4"))
        self.assertTrue(headers[2].startswith("Thread T2 'foo_thread'"))

    def test_parses_frames_with_filename_and_linenumber(self):
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        write_stack = result["stacks"][0]
        self.assertEqual(write_stack["thread"], "T2")
        self.assertEqual(
            write_stack["frames"][0],
            {
                "depth": "#0",
                "f": "foo_thread_run()",
                "filename": "../src/foo_thread.cpp",
                "linenumber": "42",
            },
        )

    def test_parses_frames_without_filename(self):
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        write_stack = result["stacks"][0]
        self.assertEqual(
            write_stack["frames"][1],
            {"depth": "#1", "f": "start_thread", "filename": None, "linenumber": None},
        )

    def test_registers_main_thread_name(self):
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        self.assertEqual(result["thread_names"]["main"], "main")
        self.assertEqual(result["stacks"][1]["thread"], "main")

    def test_registers_named_thread_from_thread_created_line(self):
        result = filter_tsan.to_json(lines_of(DATA_RACE_BLOCK))

        self.assertEqual(result["thread_names"]["T2"], "foo_thread")

    def test_registers_unnamed_thread_from_thread_created_line(self):
        result = filter_tsan.to_json(lines_of(USE_AFTER_FREE_BLOCK))

        # No quoted name in "Thread T3 (tid=...) created by ..." so the
        # thread id itself is used as the name.
        self.assertEqual(result["thread_names"]["T3"], "T3")

    def test_parses_location_is_stack(self):
        result = filter_tsan.to_json(lines_of(USE_AFTER_FREE_BLOCK))

        location_stack = result["stacks"][2]
        self.assertTrue(location_stack["header"].startswith("Location is heap block"))
        self.assertEqual(location_stack["thread"], "T4")

    def test_handles_failed_to_restore_the_stack_frame(self):
        result = filter_tsan.to_json(lines_of(USE_AFTER_FREE_BLOCK))

        thread_created_stack = result["stacks"][-1]
        self.assertTrue(thread_created_stack["header"].startswith("Thread T3"))
        self.assertEqual(len(thread_created_stack["frames"]), 1)
        frame = thread_created_stack["frames"][0]
        self.assertIsNone(frame["depth"])
        self.assertIsNone(frame["filename"])
        self.assertIn("failed to restore the stack", frame["f"])


class MainEndToEndTests(unittest.TestCase):
    def run_cli(self, *extra_args):
        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "tsan.log"
            log_path.write_text(DATA_RACE_BLOCK + "\n" + USE_AFTER_FREE_BLOCK, encoding="utf-8")

            return subprocess.run(
                [
                    sys.executable,
                    str(Path(filter_tsan.__file__)),
                    "--filename",
                    str(log_path),
                    *extra_args,
                ],
                capture_output=True,
                text=True,
                check=True,
            )

    def test_plain_output_contains_both_warnings_by_default(self):
        result = self.run_cli()

        self.assertIn("foo_thread_run", result.stdout)
        self.assertIn("bar_thread_run", result.stdout)

    def test_keep_containing_only_keeps_matching_warning(self):
        result = self.run_cli("--keep-containing", "foo_thread")

        self.assertIn("foo_thread_run", result.stdout)
        self.assertNotIn("bar_thread_run", result.stdout)

    def test_remove_containing_drops_matching_warning(self):
        result = self.run_cli("--remove-containing", "bar_thread")

        self.assertIn("foo_thread_run", result.stdout)
        self.assertNotIn("bar_thread_run", result.stdout)

    def test_as_json_produces_two_valid_warnings_with_all_stacks(self):
        result = self.run_cli("--as-json")

        warnings = json.loads(result.stdout)
        self.assertEqual(len(warnings), 2)
        for warning in warnings:
            self.assertIn("warning", warning)
            self.assertIn("summary", warning)
            self.assertIn("stacks", warning)
            self.assertIn("thread_names", warning)
        # Every stack section, including the trailing "Thread ... created by"
        # section, should have made it into the JSON output.
        self.assertEqual(len(warnings[0]["stacks"]), 3)
        self.assertEqual(len(warnings[1]["stacks"]), 4)


if __name__ == "__main__":
    unittest.main()
