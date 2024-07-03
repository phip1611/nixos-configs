{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  imports = [
    ./auto-upgrade.nix
    ./docker.nix
    ./documentation.nix
    ./firmware.nix
    ./nix-cfg.nix
    ./nix-path-from-flake.nix
    ./self-binary-cache.nix
  ];

  options = {
    phip1611.common.system = {
      enable = lib.mkEnableOption "Enable the common system module";
      # Only server-environments should enable that.
      withAutoUpgrade = lib.mkEnableOption "Enable automatic system upgrades from this flake on GitHub";
      withDocker = lib.mkEnableOption "Enable (rootless) docker";
    };
  };

  config = lib.mkIf cfg.enable {
    # Set some defaults.
    phip1611.common.system.withDocker = lib.mkDefault true;
    phip1611.common.system.withSelfBinaryCache = lib.mkDefault true;

    # Use latest stable kernel.
    # to disable set to: `lib.mkForce pkgs.linuxPackages; # default`
    boot.kernelPackages = pkgs.linuxPackages_latest;
    # Living on the edge. 2-5% faster compilation times.
    boot.kernelParams = [ "mitigations=off" ];

    # Don't accumulate crap.
    boot.tmp.cleanOnBoot = true;

    # I use german QWERTZ layout everywhere.
    console.keyMap = "de";

    # When unpatched dynamically linked programs are executed, they fail with
    # file not found. Usually, the file "/lib64/ld-linux-x86-x64.so.2" is not
    # found. This NixOS package adds a compatibility layer for that case.
    #
    # if true: Sets the NIX_LD and NIX_LD_LIBRARY_PATH env variables and adds
    # "programs.nix-ld.libraries" to environment.systemPackages.
    #
    # Caution: For reproducibility and less global state, it would be much
    # better to set the env var NIX_LD_LIBRARY_PATH only for specific bins, such
    # as through a nix shell.
    programs.nix-ld.enable = true;

    # Set sudo password timeout to 30 min instead of 5 min.
    security.sudo.extraConfig = ''
      Defaults        timestamp_timeout=30
    '';

    # Don't accumulate crap.
    services.journald.extraConfig = ''
      SystemMaxUse=250M
      SystemMaxFileSize=50M
    '';

    # zram swap seems to enable a quicker and more responsive system when
    # memory usage is high.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };
  };
}
