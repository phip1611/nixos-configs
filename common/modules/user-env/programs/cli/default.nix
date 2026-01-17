# All CLI tools.

{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
    };
  };
  python3Toolchain = import ./_python3-toolchain.nix { inherit pkgs; };
in
{
  imports = [
    ./dev
    ./git.nix
    ./micro.nix
    ./media.nix
    ./zsh.nix
  ];
  config = lib.mkIf cfg.enable {
    programs.htop.enable = true;
    programs.iftop.enable = true;
    programs.traceroute.enable = true;

    home-manager.users."${cfg.username}" = {
      # Overload CTRL+R in shell with advanced search magic
      programs.fzf.enable = true;

      programs.tmux.enable = true;
      programs.tmux.plugins = with pkgs; [
        tmuxPlugins.sensible
      ];
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

    users.users."${cfg.username}".packages = (
      with pkgs.phip1611.packages;
      [
        # All my custom packages that are not too size-intensive and should
        # not live behind any special feature gate.
        clion-exclude-direnv
        colortest
        ddns-update
        flake-prefetch
        ftp-backup
        keep-directory-diff
        link-to-copy
        nix-shell-init
        normalize-file-permissions
        strace-with-colors
        wait-host-online
        zsh-history-backup
      ]
      ++ (with pkgsUnstable; [
        ansi
        bat
        binsider
        bottom
        calc
        coreutils # default package; here only for completeness
        curlFull # Curl with HTTP3 support and more
        dig # dig and nslookup
        dust
        eza # used to be exa
        fd # better find
        file
        hexyl # hex viewer
        httpie
        iperf3
        jq # pretty-print JSON
        killall
        less
        lftp
        linux-scripts
        lshw
        lurk # cool strace alternative
        magic-wormhole-rs # e2e encrypted file transfer CLI "wormhole-rs"
        micro
        minicom # for USB serial: "sudo minicom -D /dev/ttyUSB0"
        nflz
        nix-tree # Useful to analyze Nix closure sizes
        nixfmt
        nodejs
        ookla-speedtest
        ouch # cool convenient (de)compression tool
        paging-calculator
        pciutils # lspci
        poppler-utils # for pdfunite
        python3Toolchain
        ripgrep
        strace
        tcpdump
        tldr
        tmux
        tokei
        traceroute
        tree
        ttfb
        typos
        unzip
        usbutils # lsusb
        util-linux # lsblk and more
        vim
        wambo
        wget
        whois
        xclip # for copy & paste in several tools, such as micro
        yamlfmt
        zip
        zsh
      ])
      # Don't waste disk space when not needed.
      ++ lib.optionals cfg.withPkgsJ4F (
        with pkgsUnstable;
        [
          cmatrix
          cowsay
          fortune
          hollywood
          lolcat
        ]
      )
      # Especially QEMU comes with 1+ GiB of additional dependencies, so it is
      # smart to feature-gate it.
      ++ lib.optionals cfg.withVmms (
        with pkgsUnstable;
        [
          pkgs.phip1611.packages.qemu-uefi
          pkgs.phip1611.packages.run-efi

          cloud-hypervisor
          qemu
        ]
      )
    );
  };
}
