import json
import argparse


def parse_args():
    parser = argparse.ArgumentParser(
        description="Remove duplicates from a json files containing sanitizer warnings"
    )
    parser.add_argument(
        "--filename",
        metavar="filename",
        type=str,
        required=True,
        help="The name of the file to filter.",
    )

    args = parser.parse_args()
    return args


def get_warnings_from_json(file):
    with open(file, "r") as f:
        return json.load(f)


def is_read_write_stack(stack):
    header = stack["header"]
    return (
        "read" in header or "Read" in header or "write" in header or "Write" in header
    )


def stringify_stack(stack):
    s = ""
    for frame in stack["frames"]:
        s += frame["f"]

    return s


def hash_warning(warning):
    stringified_stacks = ""
    for stack in warning["stacks"]:
        if is_read_write_stack(stack):
            stringified_stacks += stringify_stack(stack)

    return hash(stringified_stacks)


def main():
    args = parse_args()
    unique_warnings = []
    seen = set()
    for warning in get_warnings_from_json(args.filename):
        hashed = hash_warning(warning)
        if hashed not in seen:
            unique_warnings.append(warning)
            seen.add(hashed)

    print(json.dumps(unique_warnings))


if __name__ == "__main__":
    main()
