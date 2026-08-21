import re

import sanitizer_common

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
                # Also has to register main thread to be part of this warning
                data["thread_names"][thread] = thread
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
                # Also has to register main thread to be part of this warning
                data["thread_names"][thread] = thread

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
            else:
                data["thread_names"][thread] = thread

            stack["header"] = line.strip()
            stack["thread"] = thread
            continue

    # The last stack trace accumulated (e.g. the final "Thread ... created
    # by" section) is only ever flushed when a *new* stack header is seen.
    # Since there's no such trigger after the final section, flush it here
    # or its frames would silently be dropped from the output.
    add_reset_stack_trace(stack, frames)

    return data


def _starts_report(line: str) -> bool:
    return "WARNING" in line


def _ends_report(line: str) -> bool:
    return "SUMMARY" in line


def main():
    sanitizer_common.run_filter(
        "Filter a Thread Sanitizer log.",
        _starts_report,
        _ends_report,
        to_json,
    )


if __name__ == "__main__":
    main()
