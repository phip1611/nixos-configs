# phip1611's common libraries and common NixOS module

- [`libutil`](./libutil/README.md)
- [`module`](./module/README.md)
- [`pkgs`](./pkgs/README.md)

## Usage

You can consume this repository either as flake or just fetch its sources,
for example with niv. The flake (on the top-level of this repo) exposes several
attributes following the [flake conventions](https://nixos.wiki/wiki/Flakes).
You can find more in the top-level [`README.md`](/README.md).

If you don't want to use a flake, you usually can import the `default.nix` from
`/common/libutil/default.nix` or `/common/pkgs/default.nix` and get the overlays
from `/common/libutil/overlay.nix` or `/common/pkgs/overlay.nix`.

However, I recommend using this project as flake input:

```nix
{
  inputs = {
    # Used by some options of the common NixOS module. Not required if you only
    # want to use libutil or the common pkgs.
    home-manager.url = github:nix-community/home-manager/release-23.05;
    phip1611.url = github:phip1611/nixos-configs/main;
  };
  outputs = { self, phip1611, ...}@attrs:
    # use phip1611.lib.default for the library
    # use phip1611.nixosModules.default for the common NixOS module
    # use any of the other exports of the flake
    "...";
}
```

## Overlays

Some of my common libraries and packages use/provide overlays. Usually, they
all add their functionality to `pkgs.phip1611.*`.

