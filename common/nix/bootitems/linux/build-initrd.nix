# Nix derivation that creates a minimal initrd for Linux with tools from
# busybox.
#
# The initrd sets up a minimal typical Linux environment.

{ pkgs
, lib
, makeInitrd
, writers
, additionalPackages ? [ ]
}:

makeInitrd {
  contents = [{
    object = writers.writeBash "init" ''
      set -eu
      export PATH=${lib.makeBinPath
        (additionalPackages ++ (with pkgs; [
           # Basic shell dependencies
           bashInteractive
           busybox
        ]))
      }

      mkdir -p /proc /sys /tmp /run /var
      mount -t proc none /proc
      mount -t sysfs none /sys
      mount -t tmpfs none /tmp
      mount -t tmpfs none /run

      # Create device nodes.
      mdev -s

      # Enter bash (the root shell)
      setsid cttyhack bash

      poweroff -f
    '';
    symlink = "/init";
  }];
}
