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
  dev=$(upower -e 2>/dev/null | grep -m1 battery)

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
  dev=$(upower -e 2>/dev/null | grep -m1 battery)

  # No battery → fallback OK
  [[ -z "$dev" ]] && return 0

  local perc
  perc=$(upower -i "$dev" | awk -F': *' '/percentage/ {gsub("%","",$2); print $2}')

  # Cannot read percentage → fallback OK
  [[ -z "$perc" ]] && return 0

  ((perc > threshold))
}

# Checks the network: Is there a default route and is it not metered?
check_network() {
  SUCCESS=0 # network ok
  FAILURE=1 # network bad

  # Find the name of the default network interface
  dev=$(ip route list default 2>/dev/null |
    head -n 1 |
    awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

  if [[ -z "$dev" ]]; then
    log_err "No default network route found; skipping prefetch."
    return $FAILURE
  fi

  if ! command -v nmcli >/dev/null; then
    # This is the case on servers with static configuration and no network
    # manager. There, I typically have an unmetered LAN connection. Further,
    # without NetworkManager, there is no way to query that information.
    log_info "NetworkManager CLI not available; assuming connection is not metered."
    return $SUCCESS
  fi

  metered=$(
    nmcli -t -g GENERAL.METERED device show "$dev" 2>/dev/null |
      head -n1
  )

  case "$metered" in
  "no" | "no (guessed)")
    log_info "Default connection on '$dev' is not metered."
    return $SUCCESS
    ;;
  *)
    log_err "Default connection on '$dev' is metered: skipping prefetch"
    return $FAILURE
    ;;
  esac
}

if ! check_network; then
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
    nice -n 19 -- nix build -L "$ATTR" --max-jobs "$(nproc --ignore=1)" --no-link
    set -e +x
  done
else
  log_msg "Skipping flake attribute builds because the battery is low and the system is not charging."
fi

log_msg "Finished flake prefetch run."
