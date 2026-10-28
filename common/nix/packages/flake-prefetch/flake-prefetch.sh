#!/usr/bin/env bash

set -euo pipefail

# Transform the space-separated string into an array
IFS=' ' read -r -a DEV_SHELLS <<<"${DEV_SHELLS:-}"
IFS=' ' read -r -a FLAKES <<<"${FLAKES:-}"
IFS=' ' read -r -a ATTRIBUTES_TO_BUILD <<<"${ATTRIBUTES_TO_BUILD:-}"

# As user service, this runs in $HOME
# echo "PWD: $PWD"

log_stderr() {
  local level="$1"
  shift
  printf '[%s]: %s\n' "$level" "$*" >&2
}

log_msg() {
  printf '%s\n' "$*"
}

log_err() {
  log_stderr ERROR "$@"
}

log_info() {
  log_stderr INFO "$@"
}

# Returns 0 if a battery exists and is charging/fully-charged.
# On systems without a battery, always returns 0 (safe AC fallback)
is_charging() {
  local dev
  # System batteries only, not peripherals such as mouse_hidpp_battery_0.
  dev=$(upower -e 2>/dev/null | grep -m1 /battery_)

  # No battery → treat as “charging / plugged-in”
  [[ -z "$dev" ]] && return 0

  local state
  state=$(upower -i "$dev" | awk -F': *' '/state/ {print $2}')

  [[ "$state" == "charging" || "$state" == "fully-charged" ]]
}

# battery_above <threshold>
#
# Returns 0 (success) if:
#   - no battery exists (fallback OK)
#   - percentage can be read and is > threshold
#   - percentage cannot be read (fallback OK)
#
# Returns non-zero (failure) only if a valid percentage exists and is <= threshold.
battery_above() {
  local threshold="$1"
  local dev
  dev=$(upower -e 2>/dev/null | grep -m1 /battery_)

  # No battery → fallback OK
  [[ -z "$dev" ]] && return 0

  local perc
  # upower may report fractions, such as "57.3%".
  perc=$(upower -i "$dev" | awk -F': *' '/percentage/ && $2 ~ /^[0-9]/ {print int($2)}')

  # Cannot read percentage → fallback OK
  [[ -z "$perc" ]] && return 0

  ((perc > threshold))
}

# The systemd service checks this as well, but not a manual run.
if ! is-network-unmetered; then
  log_err "No network or metered connection: skipping prefetch."
  exit 1
fi

for FLAKE in "${FLAKES[@]}"; do
  log_info "Prefetching inputs for flake '$FLAKE'."
  set +e -x
  nix flake prefetch-inputs -L "$FLAKE"
  set -e +x

  log_info "Prefetching flake '$FLAKE'."
  set +e -x
  nix flake prefetch -L "$FLAKE"
  set -e +x
done

for SHELL in "${DEV_SHELLS[@]}"; do
  log_info "Prefetching development shell '$SHELL'."
  set +e -x
  nix develop -L "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  set -e +x
done

# Be graceful to our host system and prevent possibly expensive builds when
# the system is running low on battery.
if is_charging || battery_above 30; then
  for ATTR in "${ATTRIBUTES_TO_BUILD[@]}"; do
    log_info "Prefetching Nix flake attribute '$ATTR'."
    set +e -x
    # The builds run in the Nix daemon, so `nice` has no effect on them.
    # One job with all but one core keeps the system responsive.
    nix build -L "$ATTR" --max-jobs 1 --cores "$(nproc --ignore=1)" --no-link
    set -e +x
  done
else
  log_msg "Skipping flake attribute builds because the battery is low and the system is not charging."
fi

log_msg "Finished flake prefetch run."
