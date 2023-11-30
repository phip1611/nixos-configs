# Structure

- `libutil`
- `modules`





# Common NixOS Module

This directory exports a Nix flake containing my common NixOS module. It
consists of further submodules that provide various configuration options that
can be activated or deactivated on a fine-grained level.

**⚠️ This is not a full NixOS configuration but just a collection of personal
helpful NixOS modules.** Examples for a full NixOS configuration using this
common module can be found [here](_test/flake.nix) and
[here](https://github.com/phip1611/nixos-configs/blob/main/flake.nix).

There are the following major submodules available:
- [common](common/README.md): typical environment setup of a system and
  user-specific things, such as the shell and CLI tools
- [libutil](util-overlay/README.md): utility functions as Nix library and also as Nix overlay
- [network-boot](network-boot/README.md): Network Boot Setup
- [services](services/README.md): systemd Services

You can list all NixOS configurations of this module by typing
`$ ./list-nixos-options.sh`. They are all prefixed with `phip1611`.
Subdirectories have documentation either in a dedicated README or in the Nix
files.

## Compatibility and Usage
I use and tested this on a NixOS 23.11 system. The module is supposed to be used
via Nix flakes. An example `flake.nix` that describes a full and valid NixOS
configuration may look like this:

```nix
{
  inputs = {
    nixpkgs = {
      url = github:NixOS/nixpkgs/nixos-23.05;
    };
    nixpkgs-unstable = {
      url = github:NixOS/nixpkgs/nixos-unstable;
    };
    home-manager = {
      url = github:nix-community/home-manager/release-23.05;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    phip1611-common = {
      type = "github";
      owner = "phip1611";
      repo = "dotfiles";
      dir = "NixOS";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , phip1611-common
    , ...
    }@attrs:

    let
      system = "x86_64-linux";
      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          # Passes the inputs as argument to configuration.nix
          specialArgs = attrs // { inherit pkgsUnstable; };
          modules = [
            home-manager.nixosModules.home-manager
            phip1611-common.nixosModules.phip1611-common

            # your configuration using options from phip1611-common.*
            ./configuration.nix
          ];
        };
      };
    };
}
```

and the corresponding `configuration.nix` may look like this:

```nix
# Entry point into the configuration.

{ config
, pkgs
# Used by some modules to consume packages from the unstable channel.
, pkgsUnstable
, lib
, ...
}:

{
  # phip1611 dotfiles common NixOS module configuration
  phip1611 = {
    username = "pschuster";
    common = {
      enable = true;
      username = "user-name";
      user.env.git.email = "foobar@bar.de";
      user.pkgs.python3.additionalPython3Pkgs = [
        pkgs.python3Packages.pwntools
      ];
    };
    util-overlay.enable = true;
    # to find the other options, look into "_test/configuration.nix" or run
    # the "./list-nixos-options.sh" script.
  };
}
```

and build with `$ nixos-rebuild build --flake .#nixos && rm result`.

# Additional Notes
Some NixOS options require a restart of the system to have a fully applied NixOS
config, such as systemd user services.
