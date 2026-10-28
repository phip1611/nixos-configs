#!/usr/bin/env bash

# Adds GC roots for the Nix store paths that the given rustup toolchain
# directories reference, and removes roots that no toolchain needs anymore.
#
# Usage: rustup-gc-roots.sh <toolchains dir>...
# Example: rustup-gc-roots.sh /home/user/.rustup/toolchains
#
# Missing toolchain directories are skipped. If the home directory of one
# (<home>/.rustup/toolchains) is missing, for example because it is not
# mounted yet, no roots are removed.

set -euo pipefail

ROOTS_DIR=/nix/var/nix/gcroots/rustup-toolchains

mkdir -p "$ROOTS_DIR"

toolchains=()
missing_homes=()
for dir in "$@"; do
  home=$(dirname "$(dirname "$dir")")
  if [ -d "$dir" ]; then
    toolchains+=("$dir")
  elif [ ! -d "$home" ]; then
    missing_homes+=("$home")
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
  # Other errors, such as an unreadable file, must abort, or the roots
  # of the paths in that file would be removed. xargs can't tell the
  # exit codes apart, so a shell checks them per batch. sh is not in
  # the PATH of the service, so we use the bash running this script.
  store_path_re='/nix/store/[a-z0-9]{32}-[a-zA-Z0-9+._?=-]+'
  # shellcheck disable=SC2016 # The inner shell expands them.
  paths=$(
    find "${toolchains[@]}" -type f \( -perm -u+x -o -name '*.so*' \) -print0 |
      xargs -0 --no-run-if-empty "$BASH" -c \
        'grep -aohE "$0" "$@" || [ $? -eq 1 ]' "$store_path_re" |
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

# We can't know which roots the toolchains in a missing home directory
# need. Removing them would let the GC break these toolchains.
if [ ${#missing_homes[@]} -gt 0 ]; then
  echo "Missing home directories, not removing roots: ${missing_homes[*]}" >&2
  exit 0
fi

# Remove roots that no installed toolchain needs anymore, so that the
# following GC can delete their store paths.
for root in "$ROOTS_DIR"/*; do
  [ -L "$root" ] || continue
  if ! grep -qxF "/nix/store/$(basename "$root")" <<<"$paths"; then
    rm "$root"
  fi
done
