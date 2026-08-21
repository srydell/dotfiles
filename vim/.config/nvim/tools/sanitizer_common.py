"""Shared building blocks for the per-sanitizer filter_*.py tools.

Every `-fsanitize=...` report follows the same coarse shape: a line that
starts the report, zero or more indented stack traces, and a line that ends
the report. The tools in this directory (filter_tsan.py, filter_asan.py,
filter_lsan.py, filter_ubsan.py) all reuse the pipeline below and only
provide the bits that differ: how a report starts/ends, how a *new* stack
trace within a report is recognized, and how a single stack frame is parsed.
"""

import argparse
import json
import re


def build_arg_parser(description: str) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--filename",
        metavar="filename",
        type=str,
        required=True,
        help="The name of the file to filter.",
    )
    parser.add_argument(
        "--keep-containing",
        metavar="keep_containing",
        type=str,
        required=False,
        help="If a report contains this string, it is kept.",
    )
    parser.add_argument(
        "--remove-containing",
        metavar="remove_containing",
        type=str,
        required=False,
        help="If a report contains this string, it is skipped.",
    )
    parser.add_argument(
        "--as-json",
        action="store_true",
        required=False,
        help="Print the reports as json",
    )
    return parser


def collect_reports(lines, starts_report, ends_report):
    """Group raw lines into whole sanitizer reports.

    A report begins on the first line matched by `starts_report` and ends on
    the next line matched by `ends_report` (inclusive). Lines outside of a
    report (e.g. build noise interleaved in the log) are ignored.
    """
    reports = []
    current = []
    in_report = False
    for line in lines:
        if not in_report and starts_report(line):
            in_report = True

        if in_report:
            current.append(line)

        if in_report and ends_report(line):
            reports.append(current)
            current = []
            in_report = False

    return reports


def filter_reports(reports, keep_containing, remove_containing):
    """Keep only the reports matching the --keep-containing/--remove-containing filters."""
    kept = []
    for report in reports:
        text = "".join(report)
        if remove_containing and remove_containing in text:
            continue
        if keep_containing and keep_containing not in text:
            continue
        kept.append(report)
    return kept


def run_filter(description, starts_report, ends_report, to_json):
    """Shared CLI entry point for every filter_*.py tool.

    `to_json(report_lines)` turns one collected report (a list of raw lines)
    into the JSON-serializable dict described in each sanitizer's to_json().
    """
    parser = build_arg_parser(description)
    args = parser.parse_args()

    with open(args.filename) as f:
        reports = collect_reports(f.readlines(), starts_report, ends_report)

    reports = filter_reports(reports, args.keep_containing, args.remove_containing)

    if args.as_json:
        print(json.dumps([to_json(report) for report in reports]))
    else:
        for report in reports:
            print("".join(report))


# A stack frame shared by AddressSanitizer, LeakSanitizer and
# UndefinedBehaviorSanitizer looks like one of:
#
#   #0 0x417f8b in main example_HeapOutOfBounds.cc:5
#   #1 0x7fa97c09376c (/lib/x86_64-linux-gnu/libc.so.6+0x2176c)
#   #2 0x417e54 (a.out+0x417e54)
#
# i.e. a depth, an optional address, and then either "in FUNC FILE:LINE[:COL]"
# or an opaque description (library frame, missing symbols, ...).
_ADDR_FRAME_RE = re.compile(r"^\s*(#\d+)\s+(?:0x[0-9a-fA-F]+\s*)?(.*)$")
_ADDR_FRAME_LOCATION_RE = re.compile(r"^in\s+(.+?)\s+([^\s:]+):(\d+)(?::\d+)?$")


def parse_addr_frame(line: str):
    """Parse one "#N ... in FUNC FILE:LINE" style stack frame.

    Returns a frame dict (matching the schema produced by filter_tsan.py's
    to_json) or None if `line` isn't a stack frame at all.
    """
    match = _ADDR_FRAME_RE.match(line)
    if not match:
        return None

    depth, rest = match.group(1), match.group(2).strip()
    location = _ADDR_FRAME_LOCATION_RE.match(rest)
    if location:
        func, filename, linenumber = location.groups()
        return {"depth": depth, "f": func, "filename": filename, "linenumber": linenumber}

    # No file/line info: a library frame, "(binary+0xoffset)", or a bare
    # function name. Keep the text so the frame isn't silently dropped.
    text = rest[len("in ") :] if rest.startswith("in ") else rest
    return {"depth": depth, "f": text, "filename": None, "linenumber": None}


def generic_to_json(lines, warning_re, summary_re, header_res, frame_parser=parse_addr_frame):
    """Turn one collected report into the shared warning/summary/stacks JSON shape.

    - `warning_re`/`summary_re` recognize the report's opening and closing line.
    - `header_res` is a list of compiled regexes; a match starts a *new* stack
      within the report. A regex may expose a "thread" named group, which gets
      registered (self-named) in "thread_names" for the quickfix UI.
    - `frame_parser(line)` parses a single stack frame line, or returns None.
    """
    data = {"warning": "", "summary": "", "stacks": [], "thread_names": {}}
    stack = None
    frames = []

    def flush():
        nonlocal stack, frames
        if stack is not None and frames:
            stack["frames"] = frames
            data["stacks"].append(stack)
        stack, frames = None, []

    for line in lines:
        if not data["warning"] and warning_re.match(line):
            data["warning"] = line
            continue

        if summary_re.match(line):
            data["summary"] = line
            continue

        header_line = line.strip()
        matched_header = False
        for header_re in header_res:
            header_match = header_re.match(header_line)
            if header_match:
                flush()
                thread = header_match.groupdict().get("thread")
                stack = {"header": header_line, "thread": thread}
                if thread:
                    data["thread_names"].setdefault(thread, thread)
                matched_header = True
                break
        if matched_header:
            continue

        frame = frame_parser(line)
        if frame:
            if stack is None:
                # A report with no explicit stack header (e.g. UBSan, which
                # only ever has a single implicit stack) still needs
                # somewhere to put its frames.
                stack = {"header": data["warning"].strip(), "thread": None}
            frames.append(frame)
            continue

    # The last stack in a report is only flushed once a *new* header (or this
    # final call) is seen, so it must be flushed explicitly here too.
    flush()

    return data
