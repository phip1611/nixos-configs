#!/usr/bin/env bash

# Frees disk space in the target directories of Rust projects. Projects
# without a build in the last 7 days get a `cargo clean`, as I'm likely not
# actively working on them.
#
# Usage: cargo-clean-stale [--dry-run] [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper. An error only skips the affected
# project. At the end, it prints how much space it freed.

set -euo pipefail
shopt -s nullglob

# Projects without a build in this time are inactive.
MAX_AGE_DAYS=7

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

main() {
  local -a dirs
  local dir project bytes freed_bytes=0 cleaned=0

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
        continue
      fi
      if bytes=$(clean_project "$project"); then
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
  echo "Freed $(human_size "$freed_bytes") in $cleaned projects."
}

main "$@"
