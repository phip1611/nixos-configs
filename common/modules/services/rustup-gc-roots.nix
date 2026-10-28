# The Nix-packaged rustup patches every binary of an installed toolchain with
# patchelf so that it references Nix store paths (glibc as ELF interpreter,
# libraries in the rpath, the ld.lld wrapper in rustup's own store path).
# Nothing roots these paths. Once a system update replaces rustup, the Nix GC
# deletes them and the toolchain fails with "No such file or directory".
#
# This service roots these paths before each Nix GC, for the toolchains of all
# normal users.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.rustup-gc-roots;
  toolchainDirs = lib.mapAttrsToList (_: user: "${user.home}/.rustup/toolchains") (
    lib.filterAttrs (_: user: user.isNormalUser) config.users.users
  );
in
{
  options.phip1611.services.rustup-gc-roots = {
    enable = lib.mkEnableOption "Add GC roots for the Nix store paths that rustup toolchains reference";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.rustup-gc-roots = {
      description = "Add GC roots for Nix store paths of rustup toolchains";
      wantedBy = [ "nix-gc.service" ];
      before = [ "nix-gc.service" ];
      path = [ config.nix.package ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.bash} ${./rustup-gc-roots.sh} ${lib.escapeShellArgs toolchainDirs}";
        # It runs as root but only reads the toolchains and writes the GC
        # roots.
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        ReadWritePaths = [ "/nix/var/nix" ];
        PrivateNetwork = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
