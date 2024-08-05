import argparse
import json
import re


def parse_args():
    parser = argparse.ArgumentParser(description="Filter a Thread Sanitizer log.")
    parser.add_argument(
        "--filename",
        metavar="filename",
        type=str,
        required=True,
        help="The name of the file to filter.",
    )
    parser.add_argument(
        "--remove-containing",
        metavar="remove_containing",
        type=str,
        required=False,
        help="If a stack trace contains this string, it is skipped.",
    )
    parser.add_argument(
        "--as-json",
        action="store_true",
        required=False,
        help="Print the stack traces as json",
    )

    args = parser.parse_args()
    return args


# Every sanitizer warning begins with
#
#   WARNING: ...
#
# After it starts with pointing out where the reads/writes
# are of the variable in question.
#
#   Read of size 8 at ... by thread T14:
#     #0 ...
#
#   Previous write of size 8 at ... by thread T15:
#     #0 ...
#
# After that it points out the stacks where
# the threads causing the data race/heap-use-after-free
# As well as any location of stacks
#
#   Location is heap block of size 528383 at 0xffffec37f000 allocated by thread T14:
#     #0 ...
#
# After that it lists the stacks of where the threads were created.
#
#  Thread T13 'my_thread' (tid=3164, running) created by main thread at:
#    #0 pthread_create <null> (libtsan.so.0+0x2f783)
#
# Finally it ends with a
#
#   SUMMARY: ...
#
# The output of this function:
# {
#     "warning": "WARNING: ...",
#     "summary": "SUMMARY: ...",
#     "thread_names": {"T11": "my_thread", ...},
#     "stacks": [
#         {
#             "header": "Read of size 8 at ... by thread T14:",
#             "thread": "T14",
#             "frames": [
#                 {
#                     "depth": "#0",
#                     "f": "main",
#                     "filename": "src/main.cpp",
#                     "linenumber": 83,
#                 }
#             ],
#         },
#     ],
# }
def to_json(tsan_output: [str]):
    data = {"warning": "", "summary": "", "stacks": [], "thread_names": {}}

    def add_reset_stack_trace(now_stack, now_trace):
        if now_trace:
            now_stack["frames"] = now_trace.copy()
            data["stacks"].append(now_stack)
        return {"header": "", "thread": "", "frames": []}, []

    # Accumulating
    stack, frames = add_reset_stack_trace({}, [])
    for line in tsan_output:
        stack_frame = re.match(R"\s+(#\d+)\s*(.*) (([\.|/].*):(\d+)|<null>) ", line)
        if stack_frame:
            # New frames object
            frames.append(
                {
                    "depth": stack_frame.group(1),
                    "f": stack_frame.group(2),
                    "filename": stack_frame.group(4),
                    "linenumber": stack_frame.group(5),
                }
            )
            continue

        failed_to_restore_stack = re.match(
            R"\s+\[failed to restore the stack\]",
            line,
        )
        if failed_to_restore_stack:
            # New frames object
            frames.append(
                {
                    "depth": None,
                    "f": line,
                    "filename": None,
                    "linenumber": None,
                }
            )
            continue

        warning = re.match(R"WARNING: ThreadSanitizer:.*", line)
        if warning:
            data["warning"] = line
            continue

        summary = re.match("SUMMARY: ThreadSanitizer:.*", line)
        if summary:
            data["summary"] = line
            continue

        write_or_read = re.match(
            R"\s+((Previous)? [Ww]rite|(Previous)? [Rr]ead|(Previous)? [Aa]tomic (read|write)) of size (.+) by (thread (T\d+)|(main)).+",
            line,
        )
        if write_or_read:
            # New stack
            # Patch up the old
            stack, frames = add_reset_stack_trace(stack, frames)

            thread = write_or_read.group(8)
            if thread is None:
                thread = write_or_read.group(9)
            stack["header"] = line.strip()
            stack["thread"] = thread
            continue

        location_is = re.match(
            R"\s+Location is (.+) by (thread (T\d+)|(main)).+",
            line,
        )
        if location_is:
            # New stack
            # Patch up the old
            stack, frames = add_reset_stack_trace(stack, frames)

            # Either thread_id is nested within 'thread T14' -> group 3
            # or it is simply 'main' -> group 2
            thread = location_is.group(3)
            if thread is None:
                thread = location_is.group(2)

            stack["header"] = line.strip()
            stack["thread"] = thread
            continue

        thread_created = re.match(
            R"\s+Thread (T\d+) ('.+' |)\(.+\) created by .+:",
            line,
        )
        if thread_created:
            # New stack
            # Patch up the old
            stack, frames = add_reset_stack_trace(stack, frames)

            thread = thread_created.group(1).strip()
            thread_name = thread_created.group(2).strip()
            if "'" in thread_name:
                # 'my_thread' -> my_thread
                thread_name = thread_name.strip("'")
                # Register this thread as a known name
                data["thread_names"][thread] = thread_name

            stack["header"] = line.strip()
            stack["thread"] = thread
            continue

    return data


def main():
    args = parse_args()
    with open(args.filename) as f:
        in_tsan = False
        skip = False
        tsan_output = []
        # Only used when as_json flag is set
        all_json_traces = []
        for line in f.readlines():
            # Start of a TSAN stack frames
            if "WARNING" in line:
                in_tsan = True

            # Then store it for later
            if in_tsan:
                tsan_output.append(line)

            # Should we dismiss this stack frames?
            if args.remove_containing:
                if args.remove_containing in line:
                    in_tsan = False
                    tsan_output = []
                    skip = True

            # End of a TSAN stack frames
            if "SUMMARY" in line:
                if not skip:
                    if args.as_json:
                        all_json_traces.append(to_json(tsan_output))
                    else:
                        print("".join(tsan_output))

                # Reset for the next stack frames
                in_tsan = False
                skip = False
                tsan_output = []

        if args.as_json:
            print(json.dumps(all_json_traces))


if __name__ == "__main__":
    main()
