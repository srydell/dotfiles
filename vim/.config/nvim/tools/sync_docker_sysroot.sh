#!/bin/bash
# Mirrors the parts of the docker-dev container's filesystem that clangd
# needs but that aren't already bind-mounted to the host, onto the host at
# ~/.docker-dev/sysroot/<same path as in the container>.
#
# Why: clangd runs natively on macOS and can't execute the container's
# cross g++ (aarch64-redhat-linux) to ask it for its implicit system
# include directories (libstdc++, glibc, ...), so those headers must exist
# on disk for clangd to find them itself. This script copies the whole
# /opt/rh (all installed gcc-toolset-* versions, not just one) and
# /usr/include trees, so patch_compile_commands.py can later discover
# whichever toolchain a build actually used without anything here being
# pinned to a specific gcc-toolset version.
#
# patch_compile_commands.py re-runs this automatically whenever it notices
# the mirror is missing/stale (e.g. after upgrading gcc-toolset-10 ->
# gcc-toolset-11, or after the dev container itself was rebuilt/renamed), so
# you normally don't need to invoke it by hand.
set -euo pipefail

# No hardcoded default: the container is recreated (and its name can change)
# every time the dev image is upgraded, so the caller must tell us which one
# is actually running (nvim resolves this dynamically via `docker ps`, see
# srydell.util.docker_container and NVIM_DEV_CONTAINER below).
CONTAINER="${1:-${NVIM_DEV_CONTAINER:-}}"
if [ -z "$CONTAINER" ]; then
  echo "error: no container name given." >&2
  echo "Pass it as an argument, or set NVIM_DEV_CONTAINER, e.g.:" >&2
  echo "  $0 <container-name>" >&2
  echo "Find a running container with: docker ps" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "error: container '$CONTAINER' is not running." >&2
  echo "Start it, or check the correct name with: docker ps" >&2
  exit 1
fi

DEST="$HOME/.docker-dev/sysroot"

mkdir -p "$DEST/opt" "$DEST/usr"

echo "Syncing /opt/rh from $CONTAINER (gcc-toolset installs, may take a while)..."
# The mirrored tree preserves the container's original permission bits,
# which include some read-only placeholder dirs (e.g. an empty chroot-style
# root/dev, root/proc, root/sys under each gcc-toolset's runtime dir) with
# no write bit -- `rm -rf` can't unlink entries in those even though we own
# them, so restore write permission recursively before removing on a re-sync.
chmod -R u+rwX "$DEST/opt/rh" 2>/dev/null || true
rm -rf "$DEST/opt/rh"
mkdir -p "$DEST/opt/rh"
docker exec "$CONTAINER" tar -cf - -C /opt rh | tar -xf - -C "$DEST/opt"

echo "Syncing /usr/include from $CONTAINER (glibc headers)..."
chmod -R u+rwX "$DEST/usr/include" 2>/dev/null || true
rm -rf "$DEST/usr/include"
mkdir -p "$DEST/usr/include"
docker exec "$CONTAINER" tar -cf - -C /usr include | tar -xf - -C "$DEST/usr"

echo "Done. Sysroot mirrored at $DEST"
