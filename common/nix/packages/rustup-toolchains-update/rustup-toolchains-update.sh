#!/usr/bin/env bash

# Installs or updates the stable, beta, and nightly rustup toolchains of the
# host, with a fixed set of targets and, on nightly, miri. Afterwards, it
# reports the size and version of all installed toolchains, also those
# installed for other reasons, and the version of rustup.
#
# It keeps an existing default toolchain and never removes toolchains. If no
# default is set, rustup makes the first installed toolchain the default.

set -euo pipefail

TOOLCHAINS=(stable beta nightly)
TARGETS=(
  x86_64-unknown-linux-gnu
  x86_64-unknown-linux-musl
  aarch64-unknown-linux-gnu
  aarch64-unknown-linux-musl
  x86_64-unknown-uefi
  aarch64-unknown-uefi
)
# miri needs rust-src to build its sysroot.
NIGHTLY_COMPONENTS=(miri rust-src)

RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

join_by_comma() {
  local IFS=,
  echo "$*"
}

# The systemd service checks this as well, but not a manual run.
if ! is-network-unmetered; then
  echo "No network or metered connection: skipping update." >&2
  exit 1
fi

# Updates all installed channel toolchains, also those not listed above.
# The Nix-packaged rustup can't update itself.
rustup update --no-self-update

# Installs missing toolchains, targets, and components. For nightly, rustup
# picks the latest nightly that has all requested components, as miri is
# not available on every nightly. If the installed nightly lacks miri,
# that nightly can be older than the installed one, which needs
# --allow-downgrade.
for toolchain in "${TOOLCHAINS[@]}"; do
  args=(--no-self-update --profile default --target "$(join_by_comma "${TARGETS[@]}")")
  if [ "$toolchain" = nightly ]; then
    args+=(--allow-downgrade)
    args+=(--component "$(join_by_comma "${NIGHTLY_COMPONENTS[@]}")")
  fi
  rustup toolchain install "$toolchain" "${args[@]}"
done

echo
echo "Toolchain sizes in $RUSTUP_HOME/toolchains:"
du -shc "$RUSTUP_HOME"/toolchains/*

echo
echo "Versions:"
rustup --version 2>/dev/null | head -n 1
for toolchain in $(rustup toolchain list --quiet); do
  echo "$toolchain: $(rustup run "$toolchain" rustc --version)"
done
