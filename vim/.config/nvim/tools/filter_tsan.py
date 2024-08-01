import argparse


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
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    with open(args.filename) as f:
        in_tsan = False
        skip = False
        stack_trace = ""
        for line in f.readlines():
            # Start of a TSAN stack trace
            if "WARNING" in line:
                in_tsan = True

            # Then store it for later
            if in_tsan:
                stack_trace += line

            # Should we dismiss this stack trace?
            if args.remove_containing:
                if args.remove_containing in line:
                    in_tsan = False
                    stack_trace = ""
                    skip = True

            # End of a TSAN stack trace
            if "SUMMARY" in line:
                if not skip:
                    print(stack_trace)

                # Reset for the next stack trace
                in_tsan = False
                skip = False
                stack_trace = ""


if __name__ == "__main__":
    main()
