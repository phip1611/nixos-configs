# Linux bootitems

Minimal Linux kernel with a corresponding initrd.

## About / Use Case

This is useful to test functionality and configuration options of Linux or how
VMMs run this guest and present virtual hardware. It is intended to connect to
the root shell via the serial device.

Example:

```console
qemu-system-x86_64 \
  -kernel ./kernel \
  -append "console=ttyS0" \
  -initrd ./initrd" \
  -serial stdio \
  -m 1024M
```

This is tested on x86_64 only. As the initrd can become quite big, I recommend
to use not less than 700MB of RAM.

## initrd functionality

### minimal
- bash
- coreutils from busybox

### default

Everything from minimal initrd plus:

- curl
- usbutils
- pciutils

## Kernel

### Supported Versions

The kernel configuration is originally based on a
`$ make tinyconfig`-configuration of a `v6.8` kernel and might be occasionally
updated to work on the latest stable version. However, there are no strong
kernel version expectations as the required features are rather basic. Other
versions have not been tested.


### Add, Alter or Remove Configurations

To modify and tweak the configuration, it is recommended to locally check out
Linux from source and perform the following steps:

- `$ cp <path>/kernel.config <linux-src>/.config`
- `$ ln -s <path>/shell.nix <linux-src>/shell.nix`
- `$ nix-shell --pure --command "make clean|mrproper"` (optional)
- `$ nix-shell --pure --command "make menuconfig"`
- `$ nix-shell --pure --command "make bzImage -j $(nproc)"`
- `$ cp <linux-src>/.config <path>/kernel.config` (copy updated config back)

### Kernel Features & Configuration

All drivers are built-in (i.e., no module) and no drivers are loaded from the
initrd.

#### General Hardware Features & Drivers

- x86, with 64-bit, SMP, NUMA
- hypervisor detection
- timers: hpet, pm_timer
- IOMMU
- memory: no swap, huge page support
- some hardware/firmware/memory sanity checks
- serial device
- PS2 and i8042
- Para-virtualization support (for KVM)

#### Binary Structure

- BTF debug info
- Relocatable Kernel
- Xen PVH entry

#### Device and Subsystem Drivers

- USB (UHCI, EHCI, XHCI (incl. debug capability))
- PCI/PCIe and MSI
- serial I/O ports plus serial device
- virtio: blk, fs, net, rng, sockets

#### Convenience, User Experience, and APIs

- TTY via Serial
- printk
- initrd loading, ELF files, and shebang executables
  - decompress: gzip, bzip2, lzma, xz, lz0, lz4, zstd
- kernel config file is available at runtime via `/proc/config.gz`
- `/dev/[u]random` subsystem
- `/dev/mem` subsystem
- `/proc` and `/sys` file systems
- tmpfs
- `/dev/cpuid` and `/dev/msr` subsystems
- `/dev/event` subsystem (`CONFIG_INPUT` and event interface)
- BPF (but no eBPF)
- multiuser, namespaces, cgroups
- debugging helpers: verbose printk logs, tracing, stacktraces

#### Block Devices & File Systems

- basic block device support
- EXT2, EXT4, and squashfs
- DAX and FUSE_DAX support
- async I/O

#### Networking

- LAN/Ethernet but no WLAN/Wi-Fi
- IPv4 but no IPv6

#### System Calls

- epoll
- eventfd
- futex
- kexec
- seccomp
- System V IPC
- timerfd

#### ACPI

- ACPI Power, ACPI Sleep State, ACPI power button handling
  - `CONFIG_ACPI_BUTTON` can be set to `=n` and `CONFIG_ACPI_TINY_POWER_BUTTON`
    set to `=y`

#### Other

- plus all transitive dependencies
