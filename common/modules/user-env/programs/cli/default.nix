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

  # Build strace with 3rd party color patch as "strace-with-colors".
  strace-with-colors = (
    let
      colorPatchSrc = builtins.fetchTarball {
        url = "https://github.com/xfgusta/strace-with-colors/archive/refs/heads/main.tar.gz";
        sha256 = "sha256:1rgghm9knxhiw1m8sw0nim7x3qdd476d6sx83x0p3s6pc7fns3y4";
      };
      straceWithPatch = pkgs.strace.overrideAttrs {
        patches = [
          ("${colorPatchSrc}/strace-with-colors.patch")
        ];
      };
    in
    (pkgs.writeShellScriptBin "strace-with-colors" "exec -a $0 ${straceWithPatch}/bin/strace $@")
  );
in
{
  imports = [
    ./git.nix
    ./micro.nix
    ./zsh.nix
  ];
  config = lib.mkIf cfg.enable {
    programs.iftop.enable = true;
    programs.htop.enable = true;
    # Additionally to adding traceroute to the path, this enables a few cases
    # where route privileges are required.
    programs.traceroute.enable = true;

    # Very size intensive and I don't really use it. But it's cool.
    programs.yazi.enable = cfg.withPkgsJ4F;

    home-manager.users."${cfg.username}" = {
      programs.tmux.enable = true;
      programs.tmux.extraConfig = builtins.readFile ./tmux.cfg;

      # Cool modern tmux replacement with tmux key bindings compatibility.
      programs.zellij.enable = true;
      # https://zellij.dev/documentation/options
      programs.zellij.settings = {
        theme = "catppuccin-mocha";
        default_layout = "compact";
        copy_command = "xclip -selection clipboard";
        # Seems to have no effect? Do I want it at all?
        # copy_on_select = false;
        ui.pane_frames.hide_session_name = true;

        # Unbind the following keys in all modes.
        keybinds.unbind = [
          # I don't use/need the mode switch between normal and scroll. But I use
          # "Ctrl + s" often in micro, so it should work there as expected!
          "Ctrl s"

          # This way to quit is very unintuitive for me. As in tmux, I "Ctrl d"
          # until all terminals are closed.
          "Ctrl q"
        ];
      };
    };

    users.users."${cfg.username}".packages =
      (
        with pkgs; [
          # All my custom packages that are not too size-intensive and should
          # not live behind any special feature gate.
          pkgs.phip1611.packages.colortest
          pkgs.phip1611.packages.ddns-update
          pkgs.phip1611.packages.extract-vmlinux
          pkgs.phip1611.packages.ftp-backup
          pkgs.phip1611.packages.keep-directory-diff
          pkgs.phip1611.packages.link-to-copy
          pkgs.phip1611.packages.nix-shell-init
          pkgs.phip1611.packages.normalize-file-permissions

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
          lftp
          lurk # cool strace alternative
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
          ripgrep
          strace
          strace-with-colors
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
        # Dedicated feature-gate as sometimes, build problems with fresh
        # (or old) kernels occur.
        ++ lib.optional cfg.withPerf config.boot.kernelPackages.perf
        # Don't waste disk space when not needed.
        ++ lib.optionals cfg.withPkgsJ4F (with pkgs; [
          cmatrix
          cowsay
          fortune
          hollywood
          lolcat
        ])
        # Especially QEMU comes with 1+ GiB of additional dependencies, so it is
        # smart to feature-gate it.
        ++ lib.optionals cfg.withVmms (with pkgs; [
          pkgs.phip1611.packages.qemu-uefi
          pkgs.phip1611.packages.run-efi

          pkgsUnstable.cloud-hypervisor
          qemu
        ])
      );
  };
}
