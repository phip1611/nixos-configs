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

    boot.kernel.sysctl = {
      # Hide kernel logs, which help exploiting the kernel.
      "kernel.dmesg_restrict" = 1;
      "net.core.bpf_jit_harden" = 2;
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
