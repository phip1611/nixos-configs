# Server configuration.
#
# Intended for auto-update and rare active activity from myself.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = config.phip1611.common.user-env.username;
in
{
  config = {
    assertions = [
      {
        assertion = config.users.users.${username}.openssh.authorizedKeys.keys != [ ];
        message = "Servers only allow SSH public key authentication: declare a key for ${username}.";
      }
    ];

    # Public keys only. `KbdInteractiveAuthentication` must be disabled as
    # well, as it accepts passwords via PAM.
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # Hosts add further (service) users as needed.
      AllowUsers = [ username ];
      PermitRootLogin = "no";
    };

    phip1611 = {
      common = {
        user-env = {
          # Only basics, no bloat in PATH.
          enable = true;
        };

        system = {
          enable = true;
          withAutoUpgrade = true;
          # Stability is king
          withBleedingEdgeLinux = false;
          withSecureDns = true;
        };
      };
      nix-binary-cache.enable = true;
      services.zsh-history-backup.enable = true;
    };

    # Otherwise, anyone with access to the (VNC) console can edit the kernel
    # command line at boot, e.g., `init=/bin/sh`, and gain root.
    boot.loader.systemd-boot.editor = false;

    # No kexec and no hibernation: both allow replacing the running kernel.
    security.protectKernelImage = true;

    boot.kernel.sysctl = {
      # Hide kernel logs and pointers, which help exploiting the kernel.
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "net.core.bpf_jit_harden" = 2;
      # Servers don't act on or send ICMP redirects. This also matters for
      # servers that forward traffic, e.g., to containers.
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };

    # Latest LTS kernel, not latest stable kernel.
    boot.kernelPackages = pkgs.linuxPackages;

    # Only wheel members can execute sudo at all, which reduces the attack
    # surface of the setuid binary for all other (service) users.
    security.sudo.execWheelOnly = true;

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = true;

    # Shrink system closure size. Don't require perl.
    programs.command-not-found.enable = false;

    # We typically have fixed interface names in server-like setups.
    # Removing NetworkManager reduces the closure size by more than one GiB.
    networking.networkmanager.enable = false;

    xdg = {
      autostart.enable = false;
      icons.enable = false;
      mime.enable = false;
      sounds.enable = false;
    };

    nix = {
      settings = {
        # Save some disk space.
        keep-outputs = false;
        keep-derivations = false;
        # Trusted users are root-equivalent (they can, e.g., import arbitrary
        # store paths), but without the sudo password. Servers are deployed
        # locally via sudo or auto-upgrade, which don't need that.
        trusted-users = lib.mkForce [ "root" ];
      };
    };
  };
}
