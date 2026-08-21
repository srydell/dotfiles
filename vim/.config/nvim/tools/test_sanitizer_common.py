import re
import unittest

from tools import sanitizer_common


def starts_with_warning(line):
    return "WARNING" in line


def ends_with_summary(line):
    return "SUMMARY" in line


class CollectReportsTests(unittest.TestCase):
    def test_groups_lines_between_start_and_end_markers(self):
        lines = [
            "noise before\n",
            "WARNING: something\n",
            "  detail\n",
            "SUMMARY: something\n",
            "noise after\n",
        ]

        reports = sanitizer_common.collect_reports(lines, starts_with_warning, ends_with_summary)

        self.assertEqual(len(reports), 1)
        self.assertEqual(
            reports[0],
            ["WARNING: something\n", "  detail\n", "SUMMARY: something\n"],
        )

    def test_collects_multiple_reports(self):
        lines = [
            "WARNING: first\n",
            "SUMMARY: first\n",
            "WARNING: second\n",
            "SUMMARY: second\n",
        ]

        reports = sanitizer_common.collect_reports(lines, starts_with_warning, ends_with_summary)

        self.assertEqual(len(reports), 2)

    def test_ignores_lines_outside_any_report(self):
        lines = ["not part of a report\n", "still not part of one\n"]

        reports = sanitizer_common.collect_reports(lines, starts_with_warning, ends_with_summary)

        self.assertEqual(reports, [])


class FilterReportsTests(unittest.TestCase):
    def setUp(self):
        self.reports = [
            ["WARNING: race in foo_thread\n", "SUMMARY: foo_thread\n"],
            ["WARNING: race in bar_thread\n", "SUMMARY: bar_thread\n"],
        ]

    def test_no_filters_keeps_everything(self):
        kept = sanitizer_common.filter_reports(self.reports, keep_containing=None, remove_containing=None)
        self.assertEqual(kept, self.reports)

    def test_keep_containing_only_keeps_matching_reports(self):
        kept = sanitizer_common.filter_reports(self.reports, keep_containing="foo_thread", remove_containing=None)
        self.assertEqual(kept, [self.reports[0]])

    def test_remove_containing_drops_matching_reports(self):
        kept = sanitizer_common.filter_reports(self.reports, keep_containing=None, remove_containing="bar_thread")
        self.assertEqual(kept, [self.reports[0]])


class ParseAddrFrameTests(unittest.TestCase):
    def test_parses_frame_with_function_file_and_line(self):
        frame = sanitizer_common.parse_addr_frame("    #0 0x417f8b in main example_HeapOutOfBounds.cc:5\n")

        self.assertEqual(
            frame,
            {"depth": "#0", "f": "main", "filename": "example_HeapOutOfBounds.cc", "linenumber": "5"},
        )

    def test_parses_frame_with_column_after_line(self):
        frame = sanitizer_common.parse_addr_frame("#0 0x5612d124209a in main /tmp/overflow.c:4:21\n")

        self.assertEqual(frame["filename"], "/tmp/overflow.c")
        self.assertEqual(frame["linenumber"], "4")

    def test_parses_frame_with_function_containing_spaces(self):
        frame = sanitizer_common.parse_addr_frame(
            "    #0 0x40d312 in operator new[](unsigned long) /a/b/c.cc:46\n"
        )

        self.assertEqual(frame["f"], "operator new[](unsigned long)")
        self.assertEqual(frame["filename"], "/a/b/c.cc")

    def test_parses_library_frame_without_file_info(self):
        frame = sanitizer_common.parse_addr_frame("    #1 0x7fa97c09376c (/lib/x86_64-linux-gnu/libc.so.6+0x2176c)\n")

        self.assertEqual(frame["depth"], "#1")
        self.assertIsNone(frame["filename"])
        self.assertIsNone(frame["linenumber"])
        self.assertIn("libc.so.6", frame["f"])

    def test_returns_none_for_non_frame_lines(self):
        self.assertIsNone(sanitizer_common.parse_addr_frame("SUMMARY: AddressSanitizer: heap-buffer-overflow\n"))


class GenericToJsonTests(unittest.TestCase):
    def test_builds_stacks_from_header_regexes(self):
        warning_re = re.compile(r"WARNING:")
        summary_re = re.compile(r"SUMMARY:")
        header_res = [re.compile(r"^Header for (?P<thread>T\d+)$")]

        lines = [
            "WARNING: something\n",
            "Header for T1\n",
            "    #0 0x1 in foo /a.cpp:1\n",
            "SUMMARY: something\n",
        ]

        result = sanitizer_common.generic_to_json(lines, warning_re, summary_re, header_res)

        self.assertEqual(len(result["stacks"]), 1)
        self.assertEqual(result["stacks"][0]["thread"], "T1")
        self.assertEqual(result["thread_names"], {"T1": "T1"})
        self.assertEqual(result["stacks"][0]["frames"][0]["filename"], "/a.cpp")

    def test_flushes_final_stack_even_without_a_trailing_header(self):
        warning_re = re.compile(r"WARNING:")
        summary_re = re.compile(r"SUMMARY:")

        lines = [
            "WARNING: something\n",
            "    #0 0x1 in foo /a.cpp:1\n",
            "    #1 0x2 in bar /a.cpp:2\n",
            "SUMMARY: something\n",
        ]

        # No header regexes at all: every frame belongs to one implicit stack.
        result = sanitizer_common.generic_to_json(lines, warning_re, summary_re, [])

        self.assertEqual(len(result["stacks"]), 1)
        self.assertEqual(len(result["stacks"][0]["frames"]), 2)

    def test_reports_without_matching_lines_still_flush_no_empty_stack(self):
        warning_re = re.compile(r"WARNING:")
        summary_re = re.compile(r"SUMMARY:")

        lines = ["WARNING: something\n", "SUMMARY: something\n"]

        result = sanitizer_common.generic_to_json(lines, warning_re, summary_re, [])

        self.assertEqual(result["stacks"], [])


if __name__ == "__main__":
    unittest.main()
