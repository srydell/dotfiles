"""Filter and parse UndefinedBehaviorSanitizer (UBSan) logs.

Unlike TSan/ASan/LSan, a UBSan report has no "WARNING"/"ERROR" banner line;
it starts directly with the offending source location, e.g.:

    /tmp/overflow.c:4:21: runtime error: shift exponent 32 is too large ...
    #0 0x5612d124209a in main /tmp/overflow.c:4
    #1 0x7fae8909fd4f (/usr/lib64/libc.so.6+0x23d4f)

    SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior /tmp/overflow.c:4:21 in main

There's also only ever a single, implicit stack per report (no "Read of
size ..." style sub-headers), which sanitizer_common.generic_to_json()
already handles when given an empty header list.

Note: the SUMMARY line requires stack traces to be enabled
(`UBSAN_OPTIONS=print_stacktrace=1`); reports are otherwise not
terminated and will be skipped by collect_reports().

See sanitizer_common.py for the shared report-collection/JSON pipeline.
"""

import re

import sanitizer_common

WARNING_RE = re.compile(r"^\S.*: runtime error: ")
SUMMARY_RE = re.compile(r"^SUMMARY: UndefinedBehaviorSanitizer:")


def to_json(lines):
    return sanitizer_common.generic_to_json(lines, WARNING_RE, SUMMARY_RE, header_res=[])


def _starts_report(line: str) -> bool:
    return ": runtime error: " in line


def _ends_report(line: str) -> bool:
    return "SUMMARY: UndefinedBehaviorSanitizer:" in line


def main():
    sanitizer_common.run_filter(
        "Filter an UndefinedBehaviorSanitizer log.",
        _starts_report,
        _ends_report,
        to_json,
    )


if __name__ == "__main__":
    main()
