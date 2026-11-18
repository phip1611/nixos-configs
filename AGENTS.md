# AGENTS.md

This file provides guidance for AI coding agents (e.g. Codex working in this
repository.

## Repository Overview

Please find basic information about the project in `./README.md` and referenced
documentation.

In this Nix flake, I export common Nix libraries, common (self-packaged) Nix
packages, common NixOS modules, but also manage my NixOS system configurations.

I consume the exported common functionality in at least one downstream
repository, where I utilize the NixOS modules.

### Repository Structure

This is a Nix flake repository containing:

- **`common/`** - Reusable, standalone Nix libraries, packages, and NixOS
  modules intended to be consumed by out-of-tree projects as well.
  - `common/nix/libutil/` - Pure Nix utility library (`libutil`).
  - `common/nix/packages/` - Custom Nix packages.
  - `common/nix/bootitems/` - Boot-item derivations (kernels, initrds,
    tinytoykernel).
  - `common/modules/` - NixOS modules (`bootitems`, `network-boot`,
    `nix-binary-cache`, `overlays`, `services`, `system`, `user-env`).
- **`hosts/`** - Per-host NixOS system configurations. Each host has a
  `configuration.nix` as its entry point. Current hosts:
  - `asking-alexandria` - Netcup root server (x86\_64, AMD CPU).
  - `homepc` - Personal desktop (x86\_64, Intel CPU).
- **`profiles/`** - Shared NixOS profile modules (`server.nix`,
  `dev-machine.nix`) composed into host configurations.
- **`utils/`** - Utility scripts and Nix expressions (e.g.
  `list-nixos-options.nix`).
- **`flake.nix`** - Top-level entry point. Exports `checks`, `devShells`,
  `formatter`, `nixosConfigurations`, `nixosModules`, `overlays`, `packages`,
  and `lib`.

## Branch Convention

The active branch tracks the current NixOS stable release and is named after
it (e.g. `nixos-26.05`). The `nixpkgs` input in `flake.nix` is pinned to the
matching release. A `nixpkgs-unstable` input is also available to use the latest
unstable versions for some "leaf" packages (but not core system functionality).

## Language and Tooling

- All configuration is written in **Nix**. Shell scripts (`.sh`) are used for
  helper automation only.
- Formatter: `nixfmt-tree` (run via `nix fmt`).
- Spell checking: `typos` (config in `.typos.toml`).
- Editor config: `.editorconfig` defines whitespace/indent rules - respect
  them.
- Direnv: `.envrc` sets up the dev shell automatically with `nix develop`.

## Development Shell

Enter the dev shell with:

```sh
nix develop
# or, with direnv:
direnv allow
```

The shell provides `nixfmt`, `nixfmt-tree`, `nixos-rebuild`, `jq`,
`nix-output-monitor`, `yamlfmt`, and all custom packages from
`common/nix/packages/`.

## Running Checks and Tests

```sh
# Run all unit tests and evaluate all NixOS configurations:
nix flake check

# Build all NixOS configs locally (more thorough than flake check):
./build-all-configs.sh

# Build all boot items:
./build-all-bootitems.sh

# Run a specific check:
nix build .#checks.x86_64-linux.<name>

# Build a specific NixOS configuration:
nixos-rebuild build --flake .#<hostname>
```

Tests are Nix derivations; a test passes if its derivation builds
successfully. There is no separate test framework.

## Adding or Modifying Code

### Common modules (`common/modules/`)

Each module lives in its own subdirectory and is referenced from `flake.nix`
under `nixosModules`. When adding a new module:

1. Create `common/modules/<name>/default.nix`.
2. Register it in the `nixosModules` attrset in `flake.nix`.
3. If it requires an overlay, add the overlay to
  `common/nix/<component>/overlay.nix` and register it in `overlays` in
  `flake.nix`.

### Common packages (`common/nix/packages/`)

Add a new package by creating `common/nix/packages/<name>/default.nix` (or
inlining it in the packages `default.nix`). Packages are exported via the
`packages` flake output and are available in the dev shell.

### Host configurations (`hosts/`)

Each host directory must contain a `configuration.nix` that is the sole entry
point imported by `flake.nix`. Register a new host in `buildNixosSystem` calls
inside `flake.nix`. Choose an appropriate `nixos-hardware` module and profile
(`./profiles/server.nix` or `./profiles/dev-machine.nix`).

### `libutil` (`common/nix/libutil/`)

Pure functional Nix library. Unit tests live alongside the source and are
aggregated into the `allTests` derivation. Add tests next to the function
under test; follow the existing style.

## Style Guidelines

- Follow `nixfmt-tree` output exactly - run `nix fmt` before committing.
- Module option names follow the `phip1611.common.<module-name>.<option>`
  hierarchy.
- `specialArgs` in `nixosSystem` calls are flake inputs only; do not add
  arbitrary values there (it is considered an anti-pattern here).
- Each host's `configuration.nix` should import further files internally
  rather than adding more modules at the flake level, keeping `flake.nix`
  clean.
- Keep `flake.nix` inputs pinned via `follows` to avoid duplicate nixpkgs
  instances in the evaluation.

## What Agents Should NOT Do

- Do not modify `flake.lock` manually; use `nix flake update` or
  `nix flake lock --update-input <input>`.
- Do not add secrets, passwords, SSH private keys, or hardware-specific
  identifiers (UUIDs, MAC addresses) - this is a public repository.
- Do not break the `nix flake check` invariant; always verify that the
  checks pass after changes.
- Do not introduce impure Nix expressions (`builtins.currentSystem`,
  `builtins.currentTime`, IFD without necessity, etc.) into `common/`
  components that are intended to be portable.
- Do not add new flake inputs without a matching `follows` override for
  `nixpkgs` where applicable.
