# phip1611's common libraries, modules, and configurations for Nix and NixOS

## About

In this repository, you find my
[common Nix libraries and NixOS modules (`/common`)](/common/README.md) and my
public [NixOS system configurations (`/nixos-configs`)](/nixos-configs/README.md).
The top-level `flake.nix` is the entry point to all of them. The common
components can be used as standalone components in out-of-tree projects.

## Nix and NixOS Version

The whole repository is based on the referenced version of nixpkgs in
`flake.nix`. Thus, the versions of Nix and NixOS are tied to that. Usually, this
repository always follows the latest stable NixOS release.

## Building (And Switching To) a NixOS Configuration

Either clone this repository any consume the local flake or run

```shell
$ sudo nixos-rebuild switch --flake git+https://github.com/phip1611/nixos-configs#linkin-park
```

Depending on the freshness of your current system, you might need to reboot to
have all the goodness in your system.

## (Automated) Testing

In this repository, I test two aspects (in CI):

- the unit tests of [`libutil`](/common/libutil/README.md) report success
- the NixOS configurations evaluate successfully

The [common module](./common/module/README.md) is transitively tested via the
NixOS configurations that are build.

The unit tests do not follow any particular testing strategy, as there is no
common Nix unit testing framework yet. In this repo, a successful test is just a
derivation that builds successfully.

### Test Everything

Just type `$ nix flake check`. This runs unit tests (`checks` attribute) and
checks that the NixOS system configuration
[evaluate](https://github.com/NixOS/nix/blob/3c200da242d8f0ccda447866028bb757e0b0bbd9/src/nix/flake.cc#L488)
to a derivation. If a NixOS system configuration evaluates, it will also build.
(Please correct me if I'm wrong!).

You can run `./build-all-configs.sh` to build all NixOS configs locally.
However, this should never be needed for testing, as evaluation should be good
enough.

### Build (Run) Specific Tests

To run a specific check, run:

```shell
$ nix build .\#checks.x86_64-linux.default
```

or for a NixOS configuration, run

```console
$ nixos-rebuild build --flake .#<system name>
```

## Nix Flake Exports

The top-level Nix flake exports the following attributes (following the [Nix
flake conventions](https://nixos.wiki/wiki/Flakes)):

- `apps`: not used; you can `nix run` all packages also from the `packages`
          export
- `checks`: various unit tests
- `devShells`
  - everything needed to build and format this repository
  - all custom pkgs from `libutil`
  - additional util packages for this repository
- `nixosConfigurations`: the configurations for my NixOS systems
- `nixosModules`: my common NixOS module
- `overlays`: overlays for my common Nix pkgs and utility libraries
- `packages`:
  - all custom pkgs from `libutil`
  - additional util packages for this repository

The following non-standard attributes are exported as well:

- `lib`: `libutil` library
