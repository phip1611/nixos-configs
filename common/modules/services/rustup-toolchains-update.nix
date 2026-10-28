# Daily systemd user service that installs and updates a fixed set of rustup
# toolchains, targets, and components for every normal user. See the
# rustup-toolchains-update package for details.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.rustup-toolchains-update;
  # Get package from overlay.
  pkg = pkgs.phip1611.packages.rustup-toolchains-update.override {
    # Use the same rustup as the user environment. rustup patches the
    # toolchain binaries to reference its own store paths.
    inherit (pkgs.pkgsUnstable) rustup;
  };
in
{
  options.phip1611.services.rustup-toolchains-update = {
    enable = lib.mkEnableOption "Install and update rustup toolchains daily";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.rustup-toolchains-update = {
      description = "Install and update rustup toolchains";
      unitConfig = {
        # Skip root and system users.
        ConditionUser = "!@system";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg}";
      };
    };
    systemd.user.timers.rustup-toolchains-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # In the morning, after the weekly Nix GC at midnight.
        OnCalendar = "*-*-* 07:00:00";
        # Catch up on a missed run at the next login.
        Persistent = true;
        Unit = "rustup-toolchains-update.service";
      };
    };
  };
}
