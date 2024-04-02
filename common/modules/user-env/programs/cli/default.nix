# Some inputs refers to flake inputs.
{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
  python3Toolchain = import ../python3-toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./git.nix
    ./micro.nix
    ./tmux.nix
    ./zsh.nix
  ];
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (
      {
        programs.iftop.enable = true;
        programs.htop.enable = true;
        # Additionally to adding traceroute to the path, this enables a few cases
        # where route privileges are required.
        programs.traceroute.enable = true;
        programs.yazi.enable = false;

        users.users."${cfg.username}".packages =
          # Apply my custom packages from the overlay.
          (builtins.attrValues pkgs.phip1611.packages) ++ (
            with pkgs; [
              ansi
              bat
              bottom
              calc
              coreutils # default package; here only for completeness
              cpu-x # TUI-like equivalent to CPU-Z on Windows
              curl
              dig # dig and nslookup
              du-dust
              eza # used to be exa
              fd # better find
              file
              git
              grub2 # for grub-file
              hexyl # hex viewer
              iperf3
              jq # pretty-print JSON
              httpie
              killall
              less
              magic-wormhole # e2e encrypted file transfer "wormhole"
              micro
              # for USB serial: "sudo minicom -D /dev/ttyUSB0"
              minicom
              nflz
              nodejs
              ookla-speedtest
              ouch # cool convenient (de)compression tool
              paging-calculator
              pciutils # lspci
              config.boot.kernelPackages.perf
              # Experience shows that this is not working in all cases as intended.
              # Instead, projects should open a nix-shell like this:
              # `$ nix-shell -p openssl pkg-config`
              # pkg-config
              poppler_utils # for pdfunite
              python3Toolchain
              ripgrep
              tcpdump
              tldr
              tmux
              tokei
              traceroute
              tree
              ttfb
              pkgsUnstable.typos
              unzip
              usbutils # lsusb
              util-linux # lsblk and more
              wambo
              wget
              whois
              vim
              xclip # for copy & paste in several tools, such as micro
              yamlfmt
              zip
              zsh
              zx
            ]
          );
      }
    )
    (
      lib.mkIf cfg.withPkgsJ4F {
        users.users."${cfg.username}".packages = (
          with pkgs; [
            cmatrix
            cowsay
            fortune
            hollywood
            lolcat
          ]
        );
      }
    )
    (
      # Especially QEMU comes with 1+ GiB of additional dependencies, so it is
      # smart to feature-gate it.
      lib.mkIf cfg.withVmms {
        users.users."${cfg.username}".packages = (
          with pkgs;  [
            cloud-hypervisor
            qemu
          ]
        );
      }
    )

  ]);
}
