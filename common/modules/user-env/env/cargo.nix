# Enables a convenient development environment for cargo/Rust without adding
# Cargo or Rust to PATH. It just adds some convenience on top of it to replicate
# typical Rust/Cargo development environments.
#
# For example, with this module `cargo install|uninstall <package>` works
# within the typical `~/.cargo/bin` directory.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.user-env;

  # List of binaries to create a symlink to in `~/.cargo/bin`.
  # From my testing, adding "cargo" and "rustc" should be enough, but better
  # be safe.
  cargoSymlinkBins = [
    "cargo"
    "cargo-clippy"
    "rustc"
    "rustdoc"
    "rustfmt"
    "rustup"
  ];

  # Function that creates a list of cargo symlinks for the home-manager.
  createCargoBinSymlinks =
    mkOutOfStoreSymlink: bins:
    builtins.foldl'
      (
        acc: bin:
        {
          ".cargo/bin/${bin}".source =
            mkOutOfStoreSymlink "/etc/profiles/per-user/${cfg.username}/bin/${bin}";
        }
        // acc
      )
      { } # accumulator
      bins;

  dummyCargoEnvFile = pkgs.writeText "dummy-cargo-env-file.sh" ''
    # Dummy cargo env file generated by NixOS/home-manager.
    # This is only here so that scripts that expect this standard path to be
    # available don't fail. One example are the scripts in the cloud-hypervisor
    # repository, which source this file.
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.withDevCAndRust) {

    home-manager.users."${cfg.username}" =
      {
        # Refers to the home-manager config, not the NixOS config
        config,
        ...
      }:
      {
        home.file = createCargoBinSymlinks config.lib.file.mkOutOfStoreSymlink cargoSymlinkBins // {
          ".cargo/env".source = dummyCargoEnvFile;
        };

        # Add tools installed via cargo to the end of $PATH.
        # This gives those binaries the lowest precedence in $PATH.
        home.sessionPath = [
          "/home/${cfg.username}/.cargo/bin"
        ];
      };
  };
}
