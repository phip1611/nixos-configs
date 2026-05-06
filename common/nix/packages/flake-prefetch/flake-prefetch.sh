#!/usr/bin/env bash

set -euo pipefail

# Transform the space-separated string into an array
IFS=' ' read -r -a DEV_SHELLS <<< "${DEV_SHELLS:-}"
IFS=' ' read -r -a FLAKES <<< "${FLAKES:-}"
IFS=' ' read -r -a ATTRIBUTES_TO_BUILD <<< "${ATTRIBUTES_TO_BUILD:-}"

# As user service, this runs in $HOME
# echo "PWD: $PWD"

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

    (( perc > threshold ))
}

is_metered_connection() {
  SUCCESS=0
  FAILURE=1

  # Find the name of the default network interface
  dev=$(ip route list default 2>/dev/null \
    | head -n 1 \
    | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

  if ! which nmcli; then
    echo "Network manager not available - assuming unmetered connection"
    return $FAILURE
  fi

  metered=$(
      nmcli -t -g GENERAL.METERED device show "$dev" 2>/dev/null \
        | head -n1
  )

  if [[ -z "$dev" ]]; then
    return $FAILURE
  fi

  case "$metered" in
    "no"|"no (guessed)")
      return $FAILURE
      ;;
    *)
      echo "Connection on device $dev is metered"
      return $SUCCESS
      ;;
  esac
}

if is_metered_connection; then
  echo "Abort: The connection is metered or there is no default route"
  exit 1
fi

for FLAKE in "${FLAKES[@]}"; do
  echo "Flake input: $FLAKE"
  echo "Prefetch flake inputs ..."
  set +e -x
  nix flake prefetch-inputs -L "$FLAKE"
  set -e +x

  echo "Prefetch flake ..."
  set +e -x
  nix flake prefetch -L "$FLAKE"
  set -e +x
  echo
done

for SHELL in "${DEV_SHELLS[@]}"; do
  echo "Prefetch Nix flake dev shell: $SHELL"
  set +e -x
  nix develop -L "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  set -e +x
  echo
done

# Be graceful to our host system and prevent possibly expensive builds when
# the system is running low on battery.
if is_charging || battery_above 30; then
  for ATTR in "${ATTRIBUTES_TO_BUILD[@]}"; do
    echo "Prefetch (and possibly build) Nix flake attribute: $ATTR"
    set +e -x
    nice -n 19 -- nix build -L "$ATTR" --max-jobs "$(nproc --ignore=1)" --no-link
    set -e +x
    echo
  done
else
  echo -n "Low battery level. Skipping prefetching (and possibly building) Nix"
  echo " flake attributes."
fi


echo "done"
