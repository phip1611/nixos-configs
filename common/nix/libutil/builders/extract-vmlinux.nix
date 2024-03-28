# Runs <linux-src>/scripts/extract-vmlinux <kernel-image> in a derivation.

{ runCommandLocal
, phip1611
}:

# Nix Linux kernel derivation.
kernelImage:

runCommandLocal "extract-vmlinux-${kernelImage.name}"
{
  buildInputs = [ phip1611.packages.extract-vmlinux ];
} ''
  set -euo pipefail

  mkdir $out

  extract-vmlinux ${kernelImage}/bzImage > $out/vmlinux
''
