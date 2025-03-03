# NixOS: Network Boot Module

NixOS module providing support for network boot.


## Configuration

```nix
{
  phip1611.network-boot.enp195s0f3u1c2 = {
    tftpRoot = "/srv/tftp";
    hostIp = "192.168.44.100";
    dhcpRange = {
      from = "192.168.44.101";
      to = "192.168.44.101";
    };
    hostnameAlias = "office-testbox";
  };
}
```
