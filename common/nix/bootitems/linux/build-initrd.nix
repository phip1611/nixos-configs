# Nix derivation that creates a minimal initrd for Linux.
#
# The initrd sets up a minimal typical Linux environment and contains CLI tools
# from busybox, bash as shell, and optionally additional tools. Before it hands
# over control to the shell, it ensures that typical device nodes and kernel
# file systems, such as /dev/, /sysfs, /tmp, and /proc are available.
# Basically, this forms the userspace of a custom tiny Linux distribution.
#
# The user sees a bash shell. Once the bash shell is exited with CTRL+D or
# `exit`, the system is powered off.

{
  pkgs,
  bashInteractive,
  busybox,
  lib,
  makeInitrd,
  writeScript,
  writers,

  additionalPackages ? [ ],
}:

let
  # The one and only shell (a bash shell) the user sees. Due to the nature of
  # how I use these initrds, the machine is gracefully shut down once the
  # shell is exited (`exit` or `CTRL+D`).
  initBashShell = writers.writeBash "call-busybox-sh" ''
    source /etc/profile

    # Set shell prompt
    export PS1="bash/root# "

    # Enter bash.
    # cttyhack required because we use the serial console
    # https://github.com/brgl/busybox/blob/master/shell/cttyhack.c
    setsid cttyhack bash

    echo Exited init shell. Shutting down the system.

    # Poweroff after CTRL+D or exit
    poweroff -f
  '';
in
makeInitrd {
  contents = [
    # Forwards the init-responsibility to "init" of busybox.
    #
    # The init tool properly sets up signals as Linux expects a typical
    # init process to do. For example, this is needed to prevent SIGINIT
    # resulting in a "attempted to kill init" kernel panic.
    {
      symlink = "/init";
      object = writers.writeBash "call-busybox-init" ''
        exec ${busybox}/bin/init
      '';
    }
    # Common shell configuration/source.
    {
      symlink = "/etc/profile";
      object = writeScript "configure-shell-path" ''
        export PATH=${
          lib.makeBinPath (
            additionalPackages
            ++ (with pkgs; [
              bashInteractive
              busybox
            ])
          )
        }
      '';
    }
    # Set up some typical file-system nodes, create device-nodes.
    #
    # This file is called by the init tool of busybox. By convention, this
    # file is a shell script. See https://unix.stackexchange.com/a/56171/196386
    {
      symlink = "/etc/init.d/rcS";
      object = writers.writeBash "init-sys-fs-and-device-nodes" ''
        source /etc/profile

        echo =================================
        echo 🎉 HELLO FROM PHIPS TINY LINUX 🎉
        echo =================================

        mkdir -p /proc /sys /tmp /run /var
        mount -t proc none /proc
        mount -t sysfs none /sys
        mount -t tmpfs none /tmp
        mount -t tmpfs none /run

        # Create device nodes.
        mdev -s
      '';
    }
    # The shell that is used after the initial "ENTER" user prompt by "init".
    {
      symlink = "/bin/sh";
      object = initBashShell;
    }
  ];
}
