"""Filter and parse AddressSanitizer (ASan) logs.

A report looks like:

    ==6226==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x603e0001fdf4 ...
    READ of size 4 at 0x603e0001fdf4 thread T0
        #0 0x417f8b in main example_HeapOutOfBounds.cc:5
        #1 0x7fa97c09376c (/lib/x86_64-linux-gnu/libc.so.6+0x2176c)

    0x603e0001fdf4 is located 4 bytes to the right of 400-byte region [...]
    allocated by thread T0 here:
        #0 0x40d312 in operator new[](unsigned long) asan_new_delete.cc:46
        #1 0x417f1c in main example_HeapOutOfBounds.cc:3

    SUMMARY: AddressSanitizer: heap-buffer-overflow example_HeapOutOfBounds.cc:5 in main

See sanitizer_common.py for the shared report-collection/JSON pipeline.
"""

import re

import sanitizer_common

WARNING_RE = re.compile(r"^==\d+==ERROR: AddressSanitizer:")
SUMMARY_RE = re.compile(r"^SUMMARY: AddressSanitizer:")

# A new stack within a report starts at a "READ/WRITE of size ..." (where the
# bad access happened) or an "allocated/freed/previously allocated by thread
# ... here:" line (where the memory was (de)allocated).
HEADER_RES = [
    re.compile(r"^(?:READ|WRITE) of size \d+ at 0x[0-9a-fA-F]+ thread (?P<thread>T\d+)$"),
    re.compile(r"^(?:allocated|freed|previously allocated) by thread (?P<thread>T\d+) here:$"),
]


def to_json(lines):
    return sanitizer_common.generic_to_json(lines, WARNING_RE, SUMMARY_RE, HEADER_RES)


def _starts_report(line: str) -> bool:
    return "ERROR: AddressSanitizer:" in line


def _ends_report(line: str) -> bool:
    return "SUMMARY: AddressSanitizer:" in line


def main():
    sanitizer_common.run_filter(
        "Filter an AddressSanitizer log.",
        _starts_report,
        _ends_report,
        to_json,
    )


if __name__ == "__main__":
    main()
