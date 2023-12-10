# Python3 toolchain.

{ pkgs, lib, config, options, ... }:

let
  cfg = config.phip1611.common.user.pkgs.python3;
  username = config.phip1611.username;

  # Additional python3 packages.
  addPy3Pkgs = config.phip1611.common.user.pkgs.python3.additionalPython3Pkgs;

  # Python 3 toolchain with required packages. This is primarily required in the
  # global scope so that CLion and other IDEs (that do not get their context
  # easily from a nix-shell), can find Python properly.
  python3Toolchain = pkgs.python3.withPackages (ps: with ps; [
    # Required basic tools so that IDEs, such as CLion, see everything important
    # is available.
    pip
    setuptools
  ] ++ addPy3Pkgs);
in
{
  options = {
    phip1611.common.user.pkgs.python3 = {
      enable = lib.mkEnableOption "Enable Python3 toolchain";
      additionalPython3Pkgs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "Additional Python3 packages";
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${username}".packages = with pkgs; [
      python3Toolchain
    ];
  };
}
