#!/usr/bin/env bash

# Frees disk space in the target directories of Rust projects, based on
# their build activity in the last 7 days:
# - Projects without builds get a `cargo clean`, as I'm likely not actively
#   working on them.
# - In the other projects, it removes the build artifacts that no build
#   used, similar to `cargo sweep --time 7` [0]. Examples are old versions
#   of dependencies, other feature sets, and other profiles.
#
# Usage: cargo-clean-stale [--dry-run] [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper. An error only skips the affected
# project or profile. At the end, it prints how much space it freed.
#
# [0]: https://github.com/holmgr/cargo-sweep

set -euo pipefail
shopt -s nullglob

# Projects without a build in this time are inactive. Artifacts without a
# use in this time are unused.
MAX_AGE_DAYS=7

# Cargo appends the hash of a build unit to the names of its files and
# directories, such as deps/libfoo-0123456789abcdef.rlib. Captures the hash.
UNIT_HASH_RE='^[^.]*-([0-9a-f]{16})(\.|$)'

DRY_RUN=0

log_error() {
  echo "error: $*" >&2
}

human_size() {
  numfmt --to=iec-i --suffix=B --round=nearest "$1"
}

# Prints the total size in bytes of the given paths. Hard-linked files count
# once.
size_of() {
  printf '%s\0' "$@" | du -scb --files0-from=- | tail -n 1 | cut -f 1
}

# Returns success if the directory is a Rust project with a target directory
# that cargo created. Other build systems, such as Maven, also use target
# directories. A symlinked target directory is skipped, as `cargo clean`
# would only remove the link.
is_cargo_project() {
  local project=$1
  [ -f "$project/Cargo.toml" ] && [ ! -L "$project/target" ] &&
    grep -qs 'created by cargo' "$project/target/CACHEDIR.TAG"
}

# Returns success if a build modified a file or directory in the target
# directory recently. If find can't read everything, it assumes a recent
# build to stay on the safe side.
was_built_recently() {
  local target=$1 recent
  recent=$(find "$target" -mtime -"$MAX_AGE_DAYS" -print -quit) || return 0
  [ -n "$recent" ]
}

# Runs `cargo clean` for a project. Prints the freed bytes.
clean_project() {
  local project=$1 bytes

  bytes=$(size_of "$project/target")
  # `cargo clean --dry-run` is no option, as it writes
  # target/.rustc_info.json, which makes the project look recently built.
  if [ "$DRY_RUN" -eq 0 ]; then
    # This is cargo without rustup, so a rust-toolchain.toml doesn't make it
    # install the pinned toolchain first. `cargo clean` needs no rustc.
    # --frozen keeps it from touching Cargo.lock and the network.
    # --target-dir makes sure that it removes the checked directory, also if
    # CARGO_TARGET_DIR or a cargo config points to another one.
    if ! cargo clean --quiet --frozen --target-dir "$project/target" \
      --manifest-path "$project/Cargo.toml"; then
      log_error "$project: cargo clean failed, skipping"
      return 1
    fi
  fi
  echo "$bytes"
}

# Prints the files and directories of the build units in a profile
# directory, such as target/debug, that no build used recently. One per line.
#
# On each build, cargo reads the files in .fingerprint/<name>-<hash>/ of
# every unit in the build graph, which updates their access times. This
# requires a file system without noatime. Cargo rebuilds a removed unit when
# it needs it again.
unused_units() {
  local profile=$1 recent_units unit path
  local -A used_hashes=()

  recent_units=$(find "$profile/.fingerprint" -mindepth 2 -maxdepth 2 \
    -type f -atime -"$MAX_AGE_DAYS" -printf '%h\n') || return 1
  while read -r unit; do
    if [[ ${unit##*/} =~ $UNIT_HASH_RE ]]; then
      used_hashes[${BASH_REMATCH[1]}]=1
    fi
  done <<<"$recent_units"

  # Like cargo-sweep, keep examples/, as it only holds final artifacts.
  for path in "$profile"/{,deps/,build/,.fingerprint/}*; do
    if [[ ${path##*/} =~ $UNIT_HASH_RE ]] &&
      [ -z "${used_hashes[${BASH_REMATCH[1]}]:-}" ]; then
      echo "$path"
    fi
  done
}

# Removes the unused artifacts in a profile directory. Prints the freed
# bytes.
sweep_profile() {
  local profile=$1 unused bytes
  local -a paths

  if ! unused=$(unused_units "$profile"); then
    log_error "$profile: can't find unused artifacts, skipping"
    return 1
  fi
  if [ -z "$unused" ]; then
    echo 0
    return 0
  fi
  mapfile -t paths <<<"$unused"

  bytes=$(size_of "${paths[@]}")
  if [ "$DRY_RUN" -eq 0 ]; then
    # xargs, as the list can exceed the maximum length of a command line.
    if ! printf '%s\0' "${paths[@]}" | xargs -0 rm -rf --; then
      log_error "$profile: can't remove all unused artifacts"
      return 1
    fi
  fi
  echo "$bytes"
}

# Removes the unused artifacts in all profile directories of a project, such
# as target/debug and target/x86_64-unknown-uefi/release. Prints the freed
# bytes.
#
# TODO: The sweep relies on the internal layout of cargo's target directory,
# which may change. For example, with -Zbuild-dir-new-layout of cargo 1.99,
# there are no .fingerprint directories, and the sweep removes nothing.
# Replace it once cargo can remove unused build artifacts itself.
sweep_project() {
  local project=$1 fingerprint_dir bytes total=0

  # The lists of unused artifacts have one path per line. A newline in the
  # path would make them remove the wrong files.
  if [[ $project == *$'\n'* ]]; then
    log_error "$project: newline in the path, skipping"
    echo 0
    return 0
  fi

  while IFS= read -r -d '' fingerprint_dir; do
    if bytes=$(sweep_profile "${fingerprint_dir%/.fingerprint}"); then
      total=$((total + bytes))
    fi
  done < <(find "$project/target" -type d -name .fingerprint -prune -print0)
  echo "$total"
}

main() {
  local -a dirs
  local dir project bytes freed_bytes=0 cleaned=0 swept=0

  if [ "${1:-}" = --dry-run ]; then
    DRY_RUN=1
    shift
  fi
  dirs=("$@")
  if [ ${#dirs[@]} -eq 0 ]; then
    dirs=("$HOME/dev" "$HOME/dev/other")
  fi

  for dir in "${dirs[@]}"; do
    for project in "$dir"/*/; do
      project=${project%/}
      is_cargo_project "$project" || continue

      if was_built_recently "$project/target"; then
        bytes=$(sweep_project "$project")
        if [ "$bytes" -gt 0 ]; then
          echo "$project: swept $(human_size "$bytes")"
          swept=$((swept + 1))
          freed_bytes=$((freed_bytes + bytes))
        fi
      elif bytes=$(clean_project "$project"); then
        echo "$project: cleaned $(human_size "$bytes")," \
          "not built in the last $MAX_AGE_DAYS days"
        cleaned=$((cleaned + 1))
        freed_bytes=$((freed_bytes + bytes))
      fi
    done
  done

  echo
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run, nothing was removed."
  fi
  echo "Freed $(human_size "$freed_bytes") in $((cleaned + swept))" \
    "projects ($cleaned cleaned, $swept swept)."
}

main "$@"
