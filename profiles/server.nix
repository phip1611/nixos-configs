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
