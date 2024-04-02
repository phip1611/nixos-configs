# NixOS: Network Boot Module

This module sets up a network boot setup on the provided network interfaces.
Each interface will have an IP assigned. A
[dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) service is started in the
background that performs DHCP/BOOTP and TFTP on each interface. This way,
machines connected via the corresponding ports can:

- obtain an IP
- perform PXE network boot (via TFTP) including chainload of iPXE
- be accessed via SSH
- be accessed via Intel AMT and similar technologies

A connected machine needs to be configured for network boot in its BIOS
settings so that dnsmasq can serve network boot files. However, if you just
want to access it via SSH, it can boot normally.

## Side Effects
- All managed interfaces will be ignored by GNOME network manager.
- If the interface is not available (e.g., the docking station isn't plugged in)
  the boot may be delayed by 90s while systemd's service startup waits for the
  interface. However, the system works normal, if the managed interfaces by
  this module are not available.
- The configured tftpRoot directory is created automatically.

## Configuration

```nix
{
  phip1611.network-boot.enable = true;
  phip1611.network-boot.tftpRoot = "/tftpboot";
  phip1611.network-boot.interfaces = [
    {
      interface = "enp4s0";
      hostIp = "192.168.44.100";
      testboxIp = "192.168.44.101";
      # This field is optional. Creates an alias in /etc/hosts
      hostnameAlias = "testbox";
    }
    {
      interface = "enp4s1";
      hostIp = "192.168.44.200";
      testboxIp = "192.168.44.201";
      # This field is optional. Creates an alias in /etc/hosts
      hostnameAlias = "testbox2";
    }
  ];
}
```

### Configuration with Specialization
You can also use NixOS specializations to make the network-boot functionality
availability dependent on the selection of a boot entry. For example, if the
network boot is only useful in the docking station in the office, you can
entirely get rid of the functionality by using a specialization like this:

```nix
{
  specialisation.office-network-boot = {
    inheritParentConfig = true;
    configuration = {
      system.nixos.tags = [ "office-network-boot" ];

      phip1611.network-boot.enable = true;
      # Enable dnsmasq from my common module.
      phip1611.network-boot.tftpRoot = tftpRootSystem;
      phip1611.network-boot.interfaces = [
        {
          interface = "enp4s0";
          hostIp = "192.168.44.100";
          testboxIp = "192.168.44.101";
          hostnameAlias = "testbox";
        }
      ];
    };
  };
}
```

More info:
- <https://www.tweag.io/blog/2022-08-18-nixos-specialisations/>
- <https://search.nixos.org/options?channel=23.05&show=specialisation.%3Cname%3E.configuration&from=0&size=50&sort=relevance&type=packages&query=specialisation>


## iPXE
[iPXE](https://ipxe.org/) is PXE on steroids. In my setup, I let network-boot
clients chainload iPXE which allows me much more flexibility to bootstrap the
actual environment: load specific kernel, initrd via TFTP, HTTP, or so.

This module adds the package `pkgs.ipxeNetworkBoot` via an overlay to nixpkgs.
