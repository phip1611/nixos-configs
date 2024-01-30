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
    # use `phip1611.nixosModules.default` for the common NixOS module
    "...";
}
```

