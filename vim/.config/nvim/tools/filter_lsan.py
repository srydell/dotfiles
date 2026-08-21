"""Filter and parse LeakSanitizer (LSan) logs.

A report looks like:

    ==1234==ERROR: LeakSanitizer: detected memory leaks

    Direct leak of 7 byte(s) in 1 object(s) allocated from:
        #0 0x4af0ad in malloc
        #1 0x4ea6e4 in main /tmp/leak.cpp:4

    SUMMARY: LeakSanitizer: 7 byte(s) leaked in 1 allocation(s).

See sanitizer_common.py for the shared report-collection/JSON pipeline.
"""

import re

import sanitizer_common

WARNING_RE = re.compile(r"^==\d+==ERROR: LeakSanitizer:")
SUMMARY_RE = re.compile(r"^SUMMARY: LeakSanitizer:")

# A new stack within a report starts at a "Direct leak of ..." or "Indirect
# leak of ..." line. LSan doesn't attribute leaks to a particular thread.
HEADER_RES = [re.compile(r"^(?:Direct|Indirect) leak of .+ allocated from:$")]


def to_json(lines):
    return sanitizer_common.generic_to_json(lines, WARNING_RE, SUMMARY_RE, HEADER_RES)


def _starts_report(line: str) -> bool:
    return "ERROR: LeakSanitizer:" in line


def _ends_report(line: str) -> bool:
    return "SUMMARY: LeakSanitizer:" in line


def main():
    sanitizer_common.run_filter(
        "Filter a LeakSanitizer log.",
        _starts_report,
        _ends_report,
        to_json,
    )


if __name__ == "__main__":
    main()
