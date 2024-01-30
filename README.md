# phip1611's common libraries, modules, and configurations for Nix and NixOS

## About

In this repository, you find my
[common Nix libraries, common Nix packages, and common NixOS modules](/common/README.md)
and my public [NixOS system configurations](/hosts/README.md).
The top-level `flake.nix` is the entry point to all of them. The common
components itself are standalone and can be used by anyone in out-of-tree projects.


## Using the Common Components

You can include this project and use the common components without using the
NixOS configurations at all! To do so, please look at
[`/common/README.md`](/common/README.md).


## Nix and NixOS Version

The whole repository is based on the referenced version of nixpkgs in
`flake.nix`. Thus, the versions of Nix and NixOS required by all Nix files are
tied to that. Usually, this repository always follows the latest stable NixOS
release.


## Building (And Switching To) a NixOS Configuration

Either clone this repository and consume the local flake or run

```shell
$ nixos-rebuild <build|switch> --flake git+https://github.com/phip1611/nixos-configs#<hostname>
```

Depending on the difference between your current system and the applied NixOS
configuration, you might have to reboot so that all the goodness is fully
applied, such as environment variables, fresher Linux kernel, etc.


## (Automated) Unit and Integration Testing

In this repository, I test two aspects (in CI):

- The unit tests of [`libutil`](/common/libutil/README.md) report success
- The NixOS configurations evaluate successfully

The [common module](./common/module/README.md) is transitively tested via the
NixOS configurations that are build.

The unit tests do not follow any particular testing strategy or framework, as
there is no common Nix unit-testing framework yet (to my knowledge). In the
testing infrastructure of my repository, a successful test is just a derivation
that builds successfully.


### Run all Tests and Checks

Just type `$ nix flake check`. This runs unit tests (`checks` attribute) and
checks that the NixOS system configurations
[evaluate](https://github.com/NixOS/nix/blob/3c200da242d8f0ccda447866028bb757e0b0bbd9/src/nix/flake.cc#L488)
to valid derivations. (Please note that some errors might only be caught when
the NixOS configurations are actually build.)

You can run `$ ./build-all-configs.sh` to build all NixOS configs locally.
However, most of the time, `$ nix flake check` should be sufficient.


### Build (Run) Specific Tests

To run a specific check, run:

```shell
$ nix build .\#checks.x86_64-linux.<name>
```

or for a NixOS configuration, run

```console
$ nixos-rebuild build --flake .#<system name>
```


## Nix Flake Exports of this Repository

The top-level Nix flake exports the following attributes (following the [Nix
flake conventions](https://nixos.wiki/wiki/Flakes)):

- `apps`: not used; you can `$ nix run` all packages also from the `packages`
          export
- `checks`: various unit tests
- `devShells`
  - everything needed to build and format this repository
  - all custom pkgs from `common/pkgs`
  - additional util packages for this repository
- `nixosConfigurations`: the configurations for my NixOS systems
- `nixosModules`: my common NixOS module
- `overlays`: overlays for my common Nix pkgs and utility libraries
- `packages`:
  - all custom pkgs from `common/pkgs`
  - additional util packages for this repository

The following non-standard attributes are exported as well:

- `lib`: `libutil` library
