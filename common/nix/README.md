# My common Nix functionality

Several Nix-related subprojects. Usually, they can be used independently but
some depend on others.

## Subprojects

- [bootitems](./bootitems/README.md)
- [libutil](./libutil/README.md)
- [pkgs](./pkgs/README.md)

## Overlays

Each subproject provides a `overlay.nix` that adds its functionality to
`pkgs.phip1611.<project>`. Additionally, you can add the overlay easily to your
NixOS configuration by importing the `overlay-module.nix` file.

## Quick prototyping in a REPL or via `nix-build`

For quick prototyping and testing, you can do:

- `nix repl --file .`
- `nix-build -A <attr>`
- `nix-build -E "(import ./. {}).attr"`

## Unit Tests and Naming Convention

As there is no default Nix unit test framework yet, I use my own convention.

Everything called `testing` is supposed to be used as general test 
infrastructure and not a test itself. Everything called `tests.nix` exports an 
attribute set of unit tests. Each test is a derivation that must evaluate 
successfully.

To run all tests, run `$ nix-build -A all-tests`.
