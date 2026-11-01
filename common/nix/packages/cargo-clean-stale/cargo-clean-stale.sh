#!/usr/bin/env bash

# Frees disk space in the target directories of Rust projects. Projects
# without a build in the last 7 days get a `cargo clean`, as I'm likely not
# actively working on them.
#
# Usage: cargo-clean-stale [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper. An error only skips the affected
# project.

set -euo pipefail
shopt -s nullglob

# Projects without a build in this time are inactive.
MAX_AGE_DAYS=7

log_error() {
  echo "error: $*" >&2
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

# Runs `cargo clean` for a project.
clean_project() {
  local project=$1

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
}

main() {
  local -a dirs
  local dir project

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
      if clean_project "$project"; then
        echo "$project: cleaned, not built in the last $MAX_AGE_DAYS days"
      fi
    done
  done
}

main "$@"
