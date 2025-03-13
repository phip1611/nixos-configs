# bootitems

Collection of Nix-packaged bootitems, such as firmware, kernels, and initrds.
For example:

- Multiboot2 kernels, which I occasionally create and need for testing.
- Minimal Linux kernel and initrd (headless, connection via serial console)

## Usage Example: Linux kernel and initrd

The following bash script shows how to boot a Linux kernel and an initrd
provided by the Nix-packaged bootitems in `cloud-hypervisor`, a VMM leveraging
KVM.

```bash
# Get Nix store path to bootitems library.
export LIB=$(nix eval github:phip1611/nixos-configs#lib.bootitems)

# Lets start by getting and building kernel and initrd.
# The build might take a few minutes.

echo "Printing available kernels"
nix-instantiate --eval --expr "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.kernels
"
echo

# Select kernel version
export KERNEL_VERSION="stable"
export KERNEL=$(nix-build -E "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  lib.linux.kernels.${KERNEL_VERSION}
")
export KERNEL="$KERNEL/bzImage"

echo "Printing available initrds"
nix-instantiate --eval --expr "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.initrds
"
echo

# Select initrd
export INITRD=$(nix-build -E "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  lib.linux.initrds.minimal
")
export INITRD="$INITRD/initrd"

echo "Booting kernel=$KERNEL, initrd=$INITRd"
cloud-hypervisor \
  --kernel $KERNEL \
  --cmdline console=ttyS0 \
  --initramfs $INITRD \
  --serial tty \
  --console off
```
