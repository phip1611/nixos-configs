# Returns iPXE with an embedded configuration that performs the following steps:
# 1. dhcp
# 2. load ipxe-default.cfg from the address that served the ipxe executable

{
  callPackage,
  ipxe,
  runCommand,
  writeScript,
}:

let
  defaultCfgFile = "ipxe-default.cfg";
  embedScript = writeScript "ipxe-embed" ''
    #!ipxe
    dhcp
    chain tftp://''${next-server}/${defaultCfgFile} || shell
  '';
in
(ipxe.override {
  inherit embedScript;
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      inherit defaultCfgFile;
    };
  })
