# Tests the network-boot module: a UEFI machine boots via PXE from the server,
# loads my iPXE build via TFTP, which then runs the default iPXE configuration
# from the server.

{ pkgs, ... }:

let
  # The UEFI client on VLAN 1 of the test.
  clientStartCommand = builtins.concatStringsSep " " [
    "${pkgs.qemu_test}/bin/qemu-system-x86_64"
    "-machine accel=kvm:tcg"
    "-m 512"
    "-drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.firmware}"
    "-drive if=pflash,format=raw,unit=1,readonly=on,file=${pkgs.OVMF.variables}"
    ''-netdev vde,id=net0,sock="$QEMU_VDE_SOCKET_1"''
    # No option ROM: the firmware itself performs the PXE boot.
    "-device virtio-net-pci,netdev=net0,romfile="
    "-boot order=n"
  ];
in
{
  name = "network-boot";

  nodes.server = {
    phip1611.network-boot.eth1 = {
      # Next to the address from the test framework.
      hostIp = "192.168.1.10";
      dhcpRange = {
        from = "192.168.1.100";
        to = "192.168.1.100";
      };
      hostnameAlias = "testbox";
    };
  };

  testScript = ''
    server.wait_for_unit("dnsmasq.service")

    with subtest("the server serves the boot files"):
        server.succeed(
            "test -f /srv/tftp/ipxe.efi",
            "test -f /srv/tftp/ipxe-default.cfg",
            "getent hosts testbox | grep -q '^192.168.1.100 '",
        )

    with subtest("a UEFI machine boots via the network into my iPXE config"):
        client = create_machine('${clientStartCommand}', name="client")
        client.start()
        # Printed by the default iPXE configuration from the server.
        client.wait_for_console_text("Booting foo files for bar project", timeout=120)
        client.crash()
  '';
}
