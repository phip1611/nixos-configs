#!/usr/bin/env bash

# Frees disk space in the target directories of Rust projects, based on
# their build activity in the last 7 days:
# - Projects without builds get a `cargo clean`, as I'm likely not actively
#   working on them.
# - In the other projects, it removes the build artifacts that no build
#   used, similar to `cargo sweep --time 7` [0]. Examples are old versions
#   of dependencies, other feature sets, and other profiles. It also removes
#   unused incremental caches, which cargo-sweep keeps. It supports the
#   legacy layout of target directories and the build-dir layout v2 [1],
#   the default from cargo 1.100 on.
#
# Usage: cargo-clean-stale [--dry-run] [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper. An error only skips the affected
# project or profile, but makes it exit with status 1 at the end. This marks
# the systemd service as failed. At the end, it prints how much space it
# freed.
#
# [0]: https://github.com/holmgr/cargo-sweep
# [1]: https://github.com/rust-lang/cargo/issues/15010
# [2]: https://github.com/rust-lang/cargo/issues/5026

set -euo pipefail
shopt -s nullglob

# Projects without a build in this time are inactive. Artifacts without a
# use in this time are unused.
MAX_AGE_DAYS=7

# In the legacy layout, cargo appends the hash of a build unit to the names
# of its files and directories, such as deps/libfoo-0123456789abcdef.rlib.
# Captures the hash.
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
# directory with the legacy layout, such as target/debug, that no build used
# recently. One per line.
#
# On each build, cargo reads the files in .fingerprint/<name>-<hash>/ of
# every unit in the build graph, which updates their access times. This
# requires a file system without noatime. Cargo rebuilds a removed unit when
# it needs it again.
unused_legacy_units() {
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

# Prints the build units in a profile directory with the build-dir layout
# v2 that no build used recently. One per line.
#
# Each unit has its own directory build/<name>/<hash>/. On each build, cargo
# reads the files in its fingerprint/ directory, like in the legacy layout.
# Units without a fingerprint/ directory are kept, as it's unclear whether a
# build uses them.
unused_v2_units() {
  local profile=$1 recent_files file unit
  local -A used_units=()

  [ -d "$profile/build" ] || return 0
  recent_files=$(find "$profile/build" -mindepth 4 -maxdepth 4 -type f \
    -atime -"$MAX_AGE_DAYS" -printf '%P\n') || return 1
  while read -r file; do
    if [[ $file == */*/fingerprint/* ]]; then
      used_units[${file%/fingerprint/*}]=1
    fi
  done <<<"$recent_files"

  for unit in "$profile"/build/*/*/fingerprint/; do
    unit=${unit%/fingerprint/}
    if [[ ${unit##*/} =~ ^[0-9a-f]{16}$ ]] &&
      [ -z "${used_units[${unit#"$profile/build/"}]:-}" ]; then
      echo "$unit"
    fi
  done
}

# Returns success if a profile directory has build artifacts, but no units in
# a known layout. Without this check, the sweep would silently remove nothing
# after cargo changes its layout again.
has_unknown_layout() {
  local profile=$1
  local -a v2_units=("$profile"/build/*/*/fingerprint/)
  local -a artifacts=("$profile"/{build,deps}/*)
  [ ! -d "$profile/.fingerprint" ] && [ ${#v2_units[@]} -eq 0 ] &&
    [ ${#artifacts[@]} -gt 0 ]
}

# Prints the incremental caches in a profile directory that no build used
# recently. One per line.
#
# rustc keeps one cache per crate in incremental/<crate>-<hash>/ and only
# reads it when it compiles that crate. Without the cache, rustc compiles
# the crate from scratch once.
unused_incremental_caches() {
  local profile=$1 recent_files file cache
  local -A used_caches=()

  [ -d "$profile/incremental" ] || return 0
  recent_files=$(find "$profile/incremental" -mindepth 2 -type f \
    -atime -"$MAX_AGE_DAYS" -printf '%P\n') || return 1
  while read -r file; do
    if [ -n "$file" ]; then
      used_caches[${file%%/*}]=1
    fi
  done <<<"$recent_files"

  for cache in "$profile"/incremental/*/; do
    cache=${cache%/}
    if [ -z "${used_caches[${cache##*/}]:-}" ]; then
      echo "$cache"
    fi
  done
}

# Removes the unused artifacts in a profile directory. Prints the freed
# bytes. It runs in a subshell, which releases the cargo lock at its end.
sweep_profile() (
  local profile=$1 lock lock_fd unused bytes
  local -a paths

  # Cargo holds these locks during a build, some only shared. Removing
  # artifacts during a build could break it. Newer versions of cargo also
  # use .cargo-build-lock and .cargo-artifact-lock, and which of the locks
  # they hold exclusively depends on the version and on
  # -Zfine-grain-locking. Holding all of them exclusively works for all.
  # TODO: The locks are internal to cargo and may change.
  for lock in "$profile"/.cargo-{,build-,artifact-}lock; do
    [ -f "$lock" ] || continue
    exec {lock_fd}<"$lock"
    if ! flock --nonblock "$lock_fd"; then
      echo "$profile: cargo is running, skipping" >&2
      echo 0
      return 0
    fi
  done

  if has_unknown_layout "$profile"; then
    log_error "$profile: unknown layout, skipping"
    return 1
  fi

  # A profile can have both layouts after a cargo update.
  if ! unused=$(
    if [ -d "$profile/.fingerprint" ]; then
      unused_legacy_units "$profile"
    fi &&
      unused_v2_units "$profile" &&
      unused_incremental_caches "$profile"
  ); then
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
)

# Removes the unused artifacts in all profile directories of a project, such
# as target/debug and target/x86_64-unknown-uefi/release. Prints the freed
# bytes. Fails if it had to skip a profile due to an error.
#
# TODO: The sweep relies on the internal layouts of cargo's target directory,
# which change over time. Replace it once cargo can remove unused build
# artifacts itself [2].
sweep_project() {
  local project=$1 profile bytes total=0 status=0

  # The lists of unused artifacts have one path per line. A newline in the
  # path would make them remove the wrong files.
  if [[ $project == *$'\n'* ]]; then
    log_error "$project: newline in the path, skipping"
    echo 0
    return 1
  fi

  # Each profile directory has a .cargo-lock, in all layouts.
  while IFS= read -r -d '' profile; do
    # The sweep of another profile can remove a nested one, such as the
    # target directory of a cargo invocation in a build script.
    [ -f "$profile/.cargo-lock" ] || continue
    if bytes=$(sweep_profile "$profile"); then
      total=$((total + bytes))
    else
      status=1
    fi
  done < <(find "$project/target" -type f -name .cargo-lock -printf '%h\0')
  echo "$total"
  return "$status"
}

main() {
  local -a dirs
  local dir project bytes freed_bytes=0 cleaned=0 swept=0 failed=0

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
        if ! bytes=$(sweep_project "$project"); then
          failed=$((failed + 1))
        fi
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
      else
        failed=$((failed + 1))
      fi
    done
  done

  echo
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run, nothing was removed."
  fi
  echo "Freed $(human_size "$freed_bytes") in $((cleaned + swept))" \
    "projects ($cleaned cleaned, $swept swept)."
  if [ "$failed" -gt 0 ]; then
    log_error "$failed projects had errors, see above"
    return 1
  fi
}

main "$@"
