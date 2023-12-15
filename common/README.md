# phip1611's common libraries and common NixOS module

- [`libutil`](./libutil/README.md)
- [`module`](./module/README.md)
- [`pkgs`](./pkgs/README.md)

## Overlays

Some of my common libraries and packages use/provide overlays. Usually, they
all add their functionality to `pkgs.phip1611.*`.

## Usage (in a Nix Flake)

To use any of the common parts that are exported via the flake, do the
following:

```nix
{
  inputs = {
    phip1611 = {
      url = github:nix-community/home-manager/release-23.05;
    };
  };
  outputs = { self, phip1611, ...}@attrs:
    # use phip1611.lib.default for the library
    # use phip1611.nixosModules.default for the common NixOS module
    # use any of the other exports of phip1611
    "...";
}
```
