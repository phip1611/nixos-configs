# This Nix derivation builds iPXE for my network boot workflow.
# It contains an embedded configuration that performs the following steps:
# 1. dhcp
# 2. load ipxe-default.cfg from the address that served the ipxe executable
#
# The DNS server answers with an DHCP/BOOTP response containing the boot file
# (such as ipxe.efi) that will be loaded via tftp.

{
  callPackage,
  ipxe,
  runCommand,
  writeScript,
}:

let
  embedScript = writeScript "ipxe-embed" ''
    #!ipxe
    dhcp
    chain tftp://''${next-server}/ipxe-default.cfg || shell
  '';
  customIpxeBuilder =
    { ... }:
    (ipxe.override {
      inherit embedScript;
    });

  customIpxe = callPackage customIpxeBuilder { };
in
runCommand "filtered-ipxe-artifacts" { } ''
  mkdir $out
  cp ${customIpxe}/ipxe.efi $out/ipxe.efi
  # For legacy BIOS network boot.
  cp ${customIpxe}/undionly.kpxe $out/ipxe.kpxe
''
