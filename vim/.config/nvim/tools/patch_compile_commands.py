#!/usr/bin/env python3
"""Patches build/*/compile_commands.json entries so clangd (running natively
on macOS) can resolve headers that only physically exist relative to the
docker-dev container's filesystem layout.

Two problems are fixed per compile command:

1. `-I/root/.docker-dev/...` (conan package headers: boost, fmt, yaml-cpp,
   oal, ...) is rewritten to the equivalent host path -- the same files are
   already bind-mounted to the host at ~/.docker-dev, just under a
   different absolute path inside the container.

2. The recorded command never lists the compiler's *implicit* system
   include directories (libstdc++, glibc) -- those come from querying the
   compiler driver, which clangd can't do here since the container's cross
   g++ can't run natively on macOS. This script appends explicit
   `-isystem` flags (and `--target=<triple>`) pointing at a host-side
   mirror of those directories (see sync_docker_sysroot.sh), discovering
   the toolset version/triple actually used by each command dynamically --
   nothing here is pinned to a specific gcc-toolset version, so upgrading
   the container's toolchain only requires re-running sync_docker_sysroot.sh.

Usage: patch_compile_commands.py [build_dir ...]
  (defaults to build/debug, build/asan, build/tsan under cwd, whichever exist)

If a build references a gcc-toolset that isn't mirrored yet (never synced,
or the container was upgraded to a newer toolset), this automatically runs
sync_docker_sysroot.sh once and re-patches, so a stale mirror self-heals on
the next build instead of silently leaving std::/glibc completion broken.
"""

import glob
import json
import os
import re
import subprocess
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SYNC_SCRIPT = os.path.join(TOOLS_DIR, "sync_docker_sysroot.sh")

HOME = os.path.expanduser("~")
DOCKER_DEV_PREFIX = "/root/.docker-dev"
HOST_DOCKER_DEV = os.path.join(HOME, ".docker-dev")
SYSROOT = os.path.join(HOME, ".docker-dev", "sysroot")

TOOLSET_RE = re.compile(
    r"^(/opt/rh/gcc-toolset-\d+)/root/usr/bin/(g\+\+|gcc|cc|c\+\+)$"
)

_isystem_cache = {}
missing_toolsets = set()


def isystem_flags_for_toolset(toolset_prefix):
    """Given e.g. '/opt/rh/gcc-toolset-10', discover the mirrored libstdc++/
    gcc include dirs on the host and return the -isystem/--target flags to
    append. Returns [] (and records toolset_prefix in missing_toolsets) if
    that toolset isn't mirrored under SYSROOT yet -- either the sync script
    was never run, or the container's toolchain moved on to a version this
    mirror doesn't have (e.g. after a gcc-toolset-10 -> 11 upgrade)."""
    if toolset_prefix in _isystem_cache:
        return _isystem_cache[toolset_prefix]

    mirrored_root = SYSROOT + toolset_prefix + "/root/usr"
    lib_gcc_base = os.path.join(mirrored_root, "lib", "gcc")
    flags = []
    if not os.path.isdir(lib_gcc_base):
        missing_toolsets.add(toolset_prefix)
    else:
        for triple in sorted(os.listdir(lib_gcc_base)):
            triple_dir = os.path.join(lib_gcc_base, triple)
            if not os.path.isdir(triple_dir):
                continue
            for ver in sorted(os.listdir(triple_dir)):
                ver_dir = os.path.join(triple_dir, ver)
                if not os.path.isdir(ver_dir):
                    continue
                cxx_include = os.path.join(mirrored_root, "include", "c++", ver)
                candidates = [
                    cxx_include,
                    os.path.join(cxx_include, triple),
                    os.path.join(cxx_include, "backward"),
                    os.path.join(ver_dir, "include"),
                ]
                for candidate in candidates:
                    if os.path.isdir(candidate):
                        flags.append("-isystem" + candidate)
                flags.append("--target=" + triple)
                break  # first (only) gcc version found for this triple
            break  # first (only) triple found under this toolset

    generic_include = os.path.join(mirrored_root, "include")
    if os.path.isdir(generic_include):
        flags.append("-isystem" + generic_include)

    glibc_include = os.path.join(SYSROOT, "usr", "include")
    if os.path.isdir(glibc_include):
        flags.append("-isystem" + glibc_include)

    _isystem_cache[toolset_prefix] = flags
    return flags


def patch_entry(entry):
    args = entry.get("arguments")
    if not args:
        return entry

    new_args = [a.replace(DOCKER_DEV_PREFIX, HOST_DOCKER_DEV) for a in args]
    # Strip any -isystem/--target flags a previous run of this script already
    # appended, so re-running (e.g. immediately after an auto-triggered sync)
    # doesn't keep piling up duplicate flags on top of each other.
    new_args = [
        a
        for a in new_args
        if not (a.startswith("-isystem" + SYSROOT) or a.startswith("--target="))
    ]

    match = TOOLSET_RE.match(args[0])
    if match:
        new_args.extend(isystem_flags_for_toolset(match.group(1)))

    entry["arguments"] = new_args
    return entry


def patch_file(path):
    with open(path) as f:
        entries = json.load(f)

    for entry in entries:
        patch_entry(entry)

    with open(path, "w") as f:
        json.dump(entries, f, indent=2)
    # print('Patched {} ({} entries)'.format(path, len(entries)))


def main():
    build_dirs = sys.argv[1:]
    if not build_dirs:
        build_dirs = [
            d for d in ("build/debug", "build/asan", "build/tsan") if os.path.isdir(d)
        ]

    paths = [
        path
        for build_dir in build_dirs
        for path in glob.glob(os.path.join(build_dir, "compile_commands.json"))
    ]
    if not paths:
        print(
            "No compile_commands.json found under: {}".format(", ".join(build_dirs)),
            file=sys.stderr,
        )
        sys.exit(1)

    for path in paths:
        patch_file(path)

    if missing_toolsets:
        print(
            "{} not mirrored under {} -- running sync_docker_sysroot.sh to fix it...".format(
                ", ".join(sorted(missing_toolsets)), SYSROOT
            )
        )

        container = os.environ.get("NVIM_DEV_CONTAINER")
        if not container:
            print(
                "Warning: NVIM_DEV_CONTAINER is not set -- don't know which container "
                "to sync from (nvim normally sets this after resolving the running "
                "container via srydell.util.docker_container). Run "
                "tools/sync_docker_sysroot.sh <container-name> manually instead.",
                file=sys.stderr,
            )
            return

        result = subprocess.run(
            [SYNC_SCRIPT, container],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        print(result.stdout)

        if result.returncode != 0:
            print(
                "Warning: sync_docker_sysroot.sh failed (see output above) -- std::/glibc "
                "completion will stay broken until it succeeds (conan header paths were "
                "still fixed).",
                file=sys.stderr,
            )
            return

        # Sync succeeded: re-patch now so this same build already gets working
        # std::/glibc completion, instead of waiting for the next build.
        _isystem_cache.clear()
        missing_toolsets.clear()
        for path in paths:
            patch_file(path)

        if missing_toolsets:
            print(
                "Warning: still missing after sync: {} -- check that the container "
                "actually has this toolset installed.".format(
                    ", ".join(sorted(missing_toolsets))
                ),
                file=sys.stderr,
            )


if __name__ == "__main__":
    main()
