# bootitems

Collection of Nix-packaged bootitems, such as firmware, kernels, and initrds.
For example:

- Multiboot2 kernels, which I occasionally create and need for testing.
- Minimal Linux kernel and initrd (headless, connection via serial console)

## Usage Example: Linux kernel and initrd

### Build Everything (May Take a Couple of Minutes)

You can build all bootitems that are exported with just one invocation. This
takes longer than building individual items, but requires fewer commands:

`$ nix build .\#bootitems-combined`

respectively

`$ nix build github:phip1611/nixos-configs#bootitems-combined`

### Build Specific Bootitems

The following bash script shows how to boot a Linux kernel and an initrd
provided by the Nix-packaged bootitems in `cloud-hypervisor`, a VMM leveraging
KVM.

```bash
# Get Nix store path to bootitems library.
export LIB=$(nix eval github:phip1611/nixos-configs#lib.bootitems)
# export LIB=$PWD/common/nix/bootitems # local checkout
# You can also get the nixpkgs version from the flake, in case you do not want
# to use `<nixpkgs>` below.
# export PKGS=$(nix eval .#inputs.nixpkgs.outPath --raw)

# Lets start by getting and building kernel and initrd.
# The build might take a few minutes.

# Select kernel version
export KERNEL="stable"
export KERNEL=$(nix-build -E "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  lib.linux.kernels.$KERNEL
")
export KERNEL="$KERNEL/bzImage"


# Select initrd
export INITRD="default"
export INITRD=$(nix-build -E "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  lib.linux.initrds.$INITRD
")
export INITRD="$INITRD/initrd"

echo "Booting kernel=$KERNEL, initrd=$INITRD"
cloud-hypervisor \
  --kernel "$KERNEL" \
  --cmdline "console=ttyS0" \
  --initramfs "$INITRD" \
  --serial "tty" \
  --console "off"
```

Or a similar command line for QEMU:

```bash
qemu-system-x86_64 \
  -kernel "$KERNEL" \
  -append "console=ttyS0" \
  -initrd "$INITRD" \
  -machine q35,accel=kvm \
  -m 1G \
  -serial stdio \
  -nodefaults
```

## Print Available Kernels and Initrds

```bash
echo "Printing available kernels"
nix-instantiate --eval --expr "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.kernels
"
echo

echo "Printing available initrds"
nix-instantiate --eval --expr "
  let
    pkgs = import <nixpkgs> {};
    lib = import $LIB { inherit pkgs; };
  in
  builtins.attrNames lib.linux.initrds
"
echo
```

