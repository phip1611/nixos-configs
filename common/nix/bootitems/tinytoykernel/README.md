# tinytoykernel

A tiny x86_64 kernel that is bootable via Multiboot1, Multiboot2, and Xen PVH.
It supports the following entries:

- `Xen PVH, i386 protected-mode`
- `Multiboot1, i386 protected-mode`
- `Multiboot2, i386 protected-mode`
- `Multiboot2, EFI AMD64 long mode`

All it does is to print its boot method via the QEMU debugcon device. After
that, it exits the VMM.

## How to Boot

### QEMU

- Boot kernel via Multiboot1: \
  `$ qemu-system-x86_64 -debugcon stdio -kernel <kernel>.elf32`

### Cloud Hypervisor

- Boot kernel via XEN PVH: \
  `$ cloud-hypervisor --debug-console tty --kernel <kernel>.elf64`
