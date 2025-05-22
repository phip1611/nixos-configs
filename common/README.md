# My common Nix functionality and NixOS modules

- [`nix`](./nix/README.md): packages, libraries, and other stuff
- [`modules/`](./modules/README.md): NixOS modules

## Usage

You can consume this repository either as flake or just fetch its sources,
for example with `niv`. The flake (on the top-level of this repo) exposes
several attributes following the [flake conventions](https://nixos.wiki/wiki/Flakes).
You can find more in the top-level [`README.md`](/README.md).

If you don't want to use a flake, you usually just can import the `default.nix`
from `/common/nix/<component>/default.nix`.

However, I recommend using this project as flake input:

```nix
{
  inputs = {
    # Used by some options of the common NixOS module. Not required if you only
    # want to use my common Nix functionality.
    home-manager.url = github:nix-community/home-manager/release-23.05;
    phip1611.url = github:phip1611/nixos-configs/main;
  };
  outputs = { self, phip1611, ...}@attrs:
    # use `phip1611.lib.*` for libraries
    # use `phip1611.nixosModules.<module name>`
    "...";
}
```

## Consume NixOS Modules (Minimal approach)

To consume the minimal version of these modules, do something like this
(note that all minimal required dependencies are included):

**flake.nix:**

```nix
{
  description = "Testbox NixOS Setup";

  inputs = {
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    phip1611.url = "github:phip1611/nixos-configs/main";
    phip1611.inputs.home-manager.follows = "home-manager";
    phip1611.inputs.nixpkgs.follows = "nixpkgs";
    phip1611.inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
  };

  outputs = { self, ... }@inputs: {
    nixosConfigurations.testbox = inputs.nixpkgs.lib.nixosSystem {
      system = "x86-64-linux";
      specialArgs = inputs;
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.phip1611.nixosModules.overlays
        inputs.phip1611.nixosModules.user-env
        inputs.phip1611.nixosModules.system
      ];
    };
  };
}
```

**configuration.nix:**

```nix
{ config, pkgs, ... }:

{
  # ...
  # Minimal setup. Basic tools without all the optional (and size-intensive)
  # packages.
  phip1611 = {
    common = {
      # Enable all default options.
      user-env = {
        enable = true;
        username = "pschuster";
        withDevCAndRust = false;
        withDevJava = false;
        withDevJavascript = false;
        withDevNix = false;
        withGui = false;
        withMedia = false;
        withPkgsJ4F = false;
      };
      system = {
        enable = true;
        withAutoUpgrade = false;
        withDockerRootless = false;
      };
    };
  };
  # ...
}
```


