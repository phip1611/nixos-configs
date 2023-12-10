# Shell-related utilities.

{ pkgs, pkgsUnstable, lib, config, options, ... }:

let
  cfg = config.phip1611.common.user.pkgs.cli;
  username = config.phip1611.username;
in
{
  options = {
    phip1611.common.user.pkgs.cli.enable = lib.mkEnableOption "Enable my typical CLI tools";
  };

  config = lib.mkIf cfg.enable {
    users.users."${username}".packages = with pkgs; [
      ansi
      bat
      bottom
      calc
      cmatrix
      cowsay
      # already there automatically; here only for completeness
      coreutils
      curl
      dig # dig and nslookup
      du-dust
      eza # used to be exa
      fd # better find
      file
      fortune
      git
      hexyl # hex viewer
      iftop # network usage per interface
      iperf3
      jq # pretty-print JSON
      htop
      httpie
      killall
      less
      lolcat
      magic-wormhole # e2e encrypted file transfer "wormhole"
      micro
      nflz
      nixos-option
      nixpkgs-fmt
      ookla-speedtest # needs unfree nixpkgs
      ouch # cool convenient (de)compression tool
      paging-calculator
      pciutils # lspci
      poppler_utils # for pdfunite
      ripgrep
      tcpdump
      tldr
      tmux
      tokei
      traceroute
      tree
      ttfb
      unzip
      usbutils # lsusb
      util-linux # lsblk and more
      wambo
      wget
      whois
      vim
      xclip # for copy & paste in several tools, such as micro
      zip
      zsh
      zx
    ]
    ++
    # All packages that are not yet in nixpkgs stable that I need.
    (with pkgsUnstable; [
      # typos has frequent releases and they are not yet merged to the stable channel
      typos
    ]);

    # Additionally to adding traceroute to the path, this enables a few cases
    # where route privileges are required.
    programs.traceroute.enable = true;
    programs.yazi.enable = true;
  };
}
