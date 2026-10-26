#!/usr/bin/env bash

# Adds GC roots for the Nix store paths that the given rustup toolchain
# directories reference, and removes roots that no toolchain needs anymore.
#
# Usage: rustup-gc-roots.sh <toolchains dir>...
# Example: rustup-gc-roots.sh /home/user/.rustup/toolchains
#
# Missing toolchain directories are skipped.

set -euo pipefail

ROOTS_DIR=/nix/var/nix/gcroots/rustup-toolchains

mkdir -p "$ROOTS_DIR"

toolchains=()
for dir in "$@"; do
  if [ -d "$dir" ]; then
    toolchains+=("$dir")
  fi
done

# Collect the Nix store paths that the toolchains reference. rustup's
# patchelf patch only changes executables and shared libraries, so we
# scan only these. Scanning all files takes ~20x longer.
paths=""
if [ ${#toolchains[@]} -gt 0 ]; then
  # The store paths are plain strings in these files: the ELF
  # interpreter (glibc), rpath entries (zlib), and rustup's own store
  # path in the ld.lld wrapper script. grep keeps only the top-level
  # store path, e.g. /nix/store/<hash>-glibc-2.44-25, and sort lists
  # each path once. Result: one store path per line.
  #
  # grep exits with 1 if a batch of files has no match, which is fine.
  paths=$(
    find "${toolchains[@]}" -type f \( -perm -u+x -o -name '*.so*' \) -print0 |
      {
        xargs -0 --no-run-if-empty \
          grep -aohE '/nix/store/[a-z0-9]{32}-[a-zA-Z0-9+._?=-]+' || true
      } |
      sort -u
  )
fi

# Add one GC root per store path. The GC never deletes a rooted path
# or anything it references. So every library that the toolchains
# load from the Nix store stays, also indirect ones such as libgcc_s,
# which glibc references. Libraries in the toolchain itself, such as
# libLLVM, are not in the Nix store and the GC never touches them.
# Paths that the GC already deleted can't be rooted anymore.
for path in $paths; do
  if [ -e "$path" ]; then
    nix-store --add-root "$ROOTS_DIR/$(basename "$path")" \
      --realise "$path" >/dev/null
  else
    echo "$path is already gone; reinstall the toolchains that use it" >&2
  fi
done

# Remove roots that no installed toolchain needs anymore, so that the
# following GC can delete their store paths.
for root in "$ROOTS_DIR"/*; do
  [ -L "$root" ] || continue
  if ! grep -qxF "/nix/store/$(basename "$root")" <<<"$paths"; then
    rm "$root"
  fi
done
