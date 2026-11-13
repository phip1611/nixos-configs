# Hardening that suits servers and developer machines alike: it doesn't
# get in the way of kernel, VMM, and other low-level development.
#
# Servers add further, more restrictive settings in their profile.

{
  config,
  lib,
  ...
}:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf (cfg.enable && cfg.withHardening) {
    # Otherwise, anyone with access to the (VNC) console can edit the kernel
    # command line at boot, e.g., `init=/bin/sh`, and gain root.
    boot.loader.systemd-boot.editor = false;

    # The kernel loads these modules on demand, e.g., when an unprivileged
    # user opens a socket of such a protocol or the desktop auto-mounts a
    # (malicious) USB drive. They are rarely used and maintained, so they are
    # a common source of exploitable bugs. `modprobe <name>` still loads them.
    #
    # Taken from the removed `profiles/hardened.nix` of nixpkgs, without
    # modules that NixOS or I use: erofs (`system.etc.overlay`) and ntfs
    # (Windows partitions, the new read-write driver in recent kernels).
    boot.blacklistedKernelModules = [
      # Obscure network protocols. nixpkgs only builds them before Linux 7.1.
      "ax25"
      "netrom"
      "rose"
      # Rare filesystems.
      "adfs"
      "affs"
      "befs"
      "bfs"
      "cramfs"
      "efs"
      "f2fs"
      "freevxfs"
      "hfs"
      "hpfs"
      "jfs"
      "minix"
      "nilfs2"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "ufs"
    ];

    boot.kernel.sysctl = {
      # Hide kernel logs, which help exploiting the kernel.
      "kernel.dmesg_restrict" = 1;
      "net.core.bpf_jit_harden" = 2;
      # Root can't replace the running kernel with kexec. Unlike
      # `security.protectKernelImage`, this keeps hibernation working.
      "kernel.kexec_load_disabled" = 1;
      # Unprivileged eBPF is already disabled by default (2), but root could
      # enable it again at runtime.
      "kernel.unprivileged_bpf_disabled" = 1;
      # Don't act on or send ICMP redirects. Otherwise, anyone on the local
      # network, such as a public Wi-Fi, can reroute our traffic. This also
      # matters for machines that forward traffic, e.g., to containers.
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };
  };
}
