# Configuration for acpid from busybox to properly handle power-off
# (power-button) events.
#
# The kernel needs the following config:
# - ACPI_BUTTON=y
# - ACPI_TINY_POWER_BUTTON=n

{ writeShellScript, writers }:

let
  # The content of the script that is executed when an ACPI PWRF/power event is
  # discovered by acpid.
  #
  # As this runs in the background, we need to write the message directly to the
  # terminal device.
  powerOffScript = writeShellScript "power" ''
    echo "acpid: power-button pressed. Executing \"poweroff -f\" now" > /dev/console
    poweroff -f
  '';

  # Config for acpid.
  #
  # Maps events with name `key` (left) to `/etc/acpi/<value>` (right).
  # The latter must be an executable.
  config = writers.writeText "acpid.conf" ''
    PWRF power
  '';

  # Set's up the environment and configuration for acpid (from busybox)
  # to handle ACPI events. ACPI receives those events from the Linux kernel.
  # Currently, this is only relevant for the power-button event.
  #
  # Info: This config is incompatible with acpid from the "acpid2" project
  #       (https://sourceforge.net/projects/acpid2/)!
  #
  # For more information see:
  # - https://github.com/brgl/busybox/blob/master/util-linux/acpid.c
  # - https://wiki.alpinelinux.org/wiki/Busybox_acpid
  setupScript = writeShellScript "acpid-setup" ''
    which acpid >/dev/null 2>/dev/null || (echo "error: acpid not found!" && exit 1)

    test -d "/etc/acpi"
    test -d "/var/log"
    test -f "/etc/acpid.conf"

    # Start acpid (acpi daemon) in background.
    # Needs device /dev/input/event0 that comes from the ACPI_BUTTON kmod.
    acpid

    # Verify that acpid has started successfully in background. If not, there
    # will be a log message.
    if [ -s /var/log/acpid.log ]
    then
       echo "Starting acpid failed with:"
       cat /var/log/acpid.log
       echo
       echo "- Are the dev/input/*-devices available?"
       echo "- Is the ACPI_BUTTON module active?"
    fi
  '';
in
{
  inherit setupScript;
  initrdContents = [
    {
      symlink = "/etc/acpid.conf";
      object = config;
    }
    {
      symlink = "/etc/acpi/power";
      object = powerOffScript;
    }
  ];
}
