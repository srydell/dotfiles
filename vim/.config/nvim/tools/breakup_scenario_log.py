from pathlib import Path
import json
import re
import argparse


def parse_args():
    parser = argparse.ArgumentParser(
        description="Split up a log file from a scenario test into individual processor outputs."
    )
    parser.add_argument(
        "--input",
        metavar="input",
        type=str,
        required=True,
        help="The path to the scenario test log.",
    )
    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"The log file provided does not exist: {args.input}")
        exit(1)

    filename = Path(args.input).name
    pattern = "log_(.*).txt"
    match = re.match(pattern, filename)
    if match:
        args.test_name = match.group(1)
    else:
        print("Could not recognize scenario test log name.")
        print(f"Expected it to be on the form: {pattern}")
        exit(1)

    return args


def main():
    args = parse_args()
    json_output = {"files": []}
    with open(args.input) as f:
        # Keeps the broken up file contents
        # processor name -> [lines]
        processors = {}

        def add(processor, line):
            if processor not in processors:
                processors[processor] = [line]
            else:
                processors[processor].append(line)

        for line in f.readlines():
            broken = line.split(":")
            # Magic number of columns in log file
            if len(broken) >= 7:
                processor = broken[4]
                # Join it back together to get the
                # actual log line from that processor
                log_line = ":".join(broken[6:])
                add(processor, log_line)
            else:
                # Append to the file where no processor could be found
                add("None", line)

        split = Path("split") / Path(args.test_name)
        split.mkdir(parents=True, exist_ok=True)
        for processor, lines in processors.items():
            file = split / Path(f"{processor}.tsan")
            json_output["files"].append(str(file))
            with open(file, "w") as f:
                f.writelines(lines)

    print(json.dumps(json_output))


if __name__ == "__main__":
    main()
