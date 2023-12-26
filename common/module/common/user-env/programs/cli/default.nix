{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
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
    ./tmux.nix
    ./zsh.nix
  ];
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (
      {
        # Additionally to adding traceroute to the path, this enables a few cases
        # where route privileges are required.
        programs.traceroute.enable = true;
        programs.yazi.enable = true;

        users.users."${username}".packages =
          # Apply my custom packages from the overlay.
          (builtins.attrValues pkgs.phip1611.pkgs) ++ (
            with pkgs; [
              ansi
              bat
              bottom
              calc
              # already there automatically; here only for completeness
              coreutils
              curl
              dig # dig and nslookup
              du-dust
              eza # used to be exa
              fd # better find
              file
              git
              grub2 # for grub-file etc.
              hexyl # hex viewer
              iftop # network usage per interface
              iperf3
              jq # pretty-print JSON
              htop
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
              # Experience shows that this is not working in all cases as intended.
              # Instead, projects should open a nix-shell like this:
              # `$ nix-shell -p openssl pkg-config`
              # pkg-config
              poppler_utils # for pdfunite
              python3Toolchain
              qemu
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
              config.boot.kernelPackages.perf
            ]
          );
      }
    )
    (
      lib.mkIf cfg.withPkgsJ4F {
        users.users."${username}".packages = (
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

  ]);
}
