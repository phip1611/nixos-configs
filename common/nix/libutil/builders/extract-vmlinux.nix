# Runs <linux-src>/scripts/extract-vmlinux <kernel-image> in a derivation.

{ linux-scripts
, runCommandLocal
}:

# Nix Linux kernel derivation.
kernelImage:

runCommandLocal "extract-vmlinux-${kernelImage.name}"
{
  nativeBuildInputs = [ linux-scripts ];
} ''
  set -euo pipefail

  mkdir $out

  extract-vmlinux ${kernelImage}/bzImage > $out/vmlinux
''
