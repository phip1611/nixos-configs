#!/usr/bin/env bash

# Lists Rust projects, as a base to free the disk space of their target
# directories.
#
# Usage: cargo-clean-stale [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper.

set -euo pipefail
shopt -s nullglob

# Returns success if the directory is a Rust project with a target directory
# that cargo created. Other build systems, such as Maven, also use target
# directories. A symlinked target directory is skipped, as `cargo clean`
# would only remove the link.
is_cargo_project() {
  local project=$1
  [ -f "$project/Cargo.toml" ] && [ ! -L "$project/target" ] &&
    grep -qs 'created by cargo' "$project/target/CACHEDIR.TAG"
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

      echo "$project"
    done
  done
}

main "$@"
