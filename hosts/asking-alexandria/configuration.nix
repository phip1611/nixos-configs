# Mostly the default configuration.nix from the install wizard.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./ci-user.nix
    ./netdata.nix
    ./web-services
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = false;
  # My server obtains a IPv4 address by DHCP but not an IPv6 address. For IPv6,
  # Netcup provides me an IPv6 "/64" net. I picked the first possible IP.
  networking.interfaces.ens3 = {
    useDHCP = true; # obtain IPv4 address
    ipv6.addresses = [
      {
        address = "2a03:4000:63:d3::1";
        prefixLength = 64;
      }
    ];
  };

  phip1611 = {
    common = {
      user-env = {
        username = "phip1611";
        git.username = "Philipp Schuster";
        git.email = "phip1611@gmail.com";
      };
    };
    # This machine hosts my Nix binary cache, so it shouldn't use it itself.
    nix-binary-cache.enable = lib.mkForce false;
    # This machine acts as my CI remote builder and as my Nix binary cache.
    # Therefore, We should verify (and repair) the store frequently.
    #
    # Unlikely that ever there is something that actually needs to be repaired
    # but better be safe.
    services.nix-verify-store.enable = true;
  };

  # The binary cache serves the Nix store of this host, including the CI
  # builds, which have no GC roots. Thus, they stay in the cache until the next
  # GC. Run it after the nightly auto-upgrades fetched the latest builds.
  nix.gc.dates = lib.mkForce "Sun 04:00";
  nix.settings = {
    # In case CI fills the disk before the next GC.
    min-free = lib.mkForce (30 * 1024 * 1024 * 1024); # 30 GiB
    max-free = lib.mkForce (80 * 1024 * 1024 * 1024); # 80 GiB
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.phip1611 = {
    isNormalUser = true;
    description = "Philipp Schuster";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIByFlysjuSdICGBaDUYOq5wPSPQgPWOenBwal2PhBtd phip1611@phips-framework13"
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = lib.mkForce [ 7331 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
