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

for FLAKE in "${FLAKES[@]}"; do
  echo "Flake input: $FLAKE"
  echo "Prefetch flake inputs ..."
  set +e -x
  nix flake prefetch-inputs "$FLAKE"
  set -e +x

  echo "Prefetch flake ..."
  set +e -x
  nix flake prefetch "$FLAKE"
  set -e +x
  echo
done

for SHELL in "${DEV_SHELLS[@]}"; do
  echo "Prefetch Nix flake dev shell: $SHELL"
  set +e -x
  nix develop "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  set -e +x
  echo
done

# Be graceful to our host system and prevent possibly expensive builds when
# the system is running low on power.
if is_charging || battery_above 30; then
  for ATTR in "${ATTRIBUTES_TO_BUILD[@]}"; do
    echo "Prefetch (and possibly build) Nix flake attribute: $ATTR"
    set +e -x
    nice -n 19 -- nix build "$ATTR" --max-jobs "$(nproc --ignore=1)" --no-link
    set -e +x
    echo
  done
else
  echo -n "Low battery level. Skipping prefecthing (and possibly building) Nix"
  echo " flake attributes."
fi


echo "done"
