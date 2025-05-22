{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.system;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
  };
in
{
  imports = [
    ./auto-upgrade.nix
    ./docker.nix
    ./documentation.nix
    ./firmware.nix
    ./networking.nix
    ./nix-cfg.nix
    ./nix-path-from-flake.nix
    ./printing.nix
    ./secure-dns.nix
  ];

  options = {
    phip1611.common.system = {
      enable = lib.mkEnableOption "Enable the common system module";
      # Only server-environments should enable that.
      withAutoUpgrade = lib.mkEnableOption "Enable automatic system upgrades from this flake on GitHub";
      withBleedingEdgeLinux = lib.mkEnableOption "Enable bleeding edge Linux version and configs";
      withDockerRootless = lib.mkEnableOption "Enable rootless Docker";
      withSecureDns = lib.mkEnableOption "Enable secure DNS (DNSSec, DoH, DoT)";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Prevent frequent "/boot volume full" errors. Limit this to a sane small
        # number. Something small is suffucient due to my extensive git versioning.
        boot.loader.grub.configurationLimit = 7;
        boot.loader.systemd-boot.configurationLimit = 7;

        # Less weird shell scripts in initrd. Probably the default soon.
        # No more multiple initrds for different specialisations (that have
        # specific networking options).
        boot.initrd.systemd.enable = true;

        # Don't accumulate crap.
        boot.tmp.cleanOnBoot = true;

        # I use german QWERTZ layout everywhere.
        console.keyMap = "de";

        # Common system-wide shell alias. This will end up in the generated
        # "${shell}rc"-files in the Nix store.
        environment.shellAliases = {
          list-generations = "nixos-rebuild list-generations";
        };

        environment.systemPackages = [
          pkgsUnstable.micro
        ];

        environment.variables = {
          # TUI editor for git, "virsh edit", and other stuff.
          EDITOR = "micro";
          VISUAL = "micro";
        };

        # Always make the source of the flake from that the system was build
        # locally available. This is especially useful if I do remote
        # deployments, mess something up, and need to apply the changes directly
        # on the system to get it back online.
        environment.etc.nixos-current-system-flake-src.source = inputs.self;

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
      }
      # Use latest stable kernel and disable mitigations.
      (lib.mkIf cfg.withBleedingEdgeLinux {
        # To reset to default, set to `lib.mkForce pkgs.linuxPackages`.
        boot.kernelPackages = pkgs.linuxPackages_latest;
        # Living on the edge. 2-5% faster compilation times.
        boot.kernelParams = [ "mitigations=off" ];
      })
    ]
  );
}
