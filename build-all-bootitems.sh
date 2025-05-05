#!/usr/bin/env bash

# Script to build all bootitems exported by the Nix library.

set -euo pipefail

ARG=${1:-}

# Nix sources
PKGS=$(nix eval .#inputs.nixpkgs.outPath --raw)
LIB=$(nix eval .#lib.bootitems)

binary_cache_host=nix-binary-cache.phip1611.dev
binary_cache_user=phip1611
binary_cache_ssh_port=7331

# Populates the Nix binary cache, when not running in CI.
populate_cache() {
  if [ "$ARG" != "--ci" ]; then
    echo "Populating the Nix binary cache at $binary_cache_host"
    NIX_SSHOPTS="-p $binary_cache_ssh_port" nix copy --to ssh://$binary_cache_user@$binary_cache_host --substitute-on-destination ./result
    echo "✔️ Populated the Nix binary cache at $binary_cache_host"
  fi
}

# Read kernels to array
readarray -t KERNELS < <(nix-instantiate --json --eval --expr "
  let
    pkgs = import $PKGS {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.kernels
" | jq -r '. | values[]')

# Read initrds to array
readarray -t INITRDS < <(nix-instantiate --json --eval --expr "
  let
    pkgs = import $PKGS {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.initrds
" | jq -r '. | values[]')

for KERNEL in "${KERNELS[@]}"; do
  echo "Building Linux kernel '$KERNEL'"
  nix build --impure --expr "
    let
      pkgs = import $PKGS {};
      lib = import $LIB { inherit pkgs; };
    in
    lib.linux.kernels.$KERNEL"
  populate_cache
done
wait

for INITRD in "${INITRDS[@]}"; do
  echo "Building Linux initrd '$INITRD'"
  nix build --impure --expr "
    let
      pkgs = import $PKGS {};
      lib = import $LIB { inherit pkgs; };
    in
    lib.linux.initrds.$INITRD"
  populate_cache
done
wait

echo "Building tinytoykernel"
nix build --impure --expr "
  let
    pkgs = import $PKGS {};
    lib = import $LIB { inherit pkgs; };
  in
  lib.tinytoykernel"
populate_cache
