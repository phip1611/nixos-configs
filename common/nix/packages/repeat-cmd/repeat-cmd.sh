#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# Example invocation:
# repeat-cmd -- bash ./scripts/dev_cli.sh tests --integration -- --test-filter "test_live_migration_tcp_timeout"
#
# @describe Repeat a command until it fails (default) or succeeds.
# @flag -i --invert Repeat until the command succeeds instead
# @arg command+ Command and arguments to execute

set -euo pipefail

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

iteration=1

trap '
  printf "\n[repeat-cmd] interrupted after %d iterations\n" "$iteration" >&2
  exit 130
' INT

while true; do
  printf '[repeat-cmd] iteration %d\n' "$iteration" >&2

  if "${argc_command[@]}"; then
    rc=0
  else
    rc=$?
  fi

  # SIGINT / Ctrl+C is conventionally reported as 128 + SIGINT(2) = 130.
  # Handle it separately so it is not mistaken for a normal command failure.
  if (( rc == 130 )); then
    printf '\n[repeat-cmd] interrupted after %d iterations\n' \
      "$iteration" >&2
    exit 130
  fi

  if [[ -n "${argc_invert:-}" ]]; then
    if (( rc == 0 )); then
      printf '[repeat-cmd] succeeded after %d iterations\n' \
        "$iteration" >&2
      exit 0
    fi
  else
    if (( rc != 0 )); then
      printf '[repeat-cmd] failed after %d iterations (exit code %d)\n' \
        "$iteration" "$rc" >&2
      exit "$rc"
    fi
  fi

  ((iteration++))
done
