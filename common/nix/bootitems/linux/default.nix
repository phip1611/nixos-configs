{ pkgs }:

let
  lib = pkgs.lib;
in
{
  # Attribute set with minimal Linux kernel in different versions.
  kernels =
    let
      # List of kernel source trees.
      kernelSourcesList = lib.lists.unique [
        # Current stable kernel
        ({
          kernel = pkgs.linux;
          aliases = [
            "stable"
            "lts"
          ];
        })
        # Latest kernel
        ({
          kernel = pkgs.linux_latest;
          aliases = [
            "latest"
          ];
        })
      ];

      # Makes the version name more Nix friendly, so that typical convenience
      # in a Nix repl for example still work.
      # - no "."
      # - don't start with a digit
      versionToAttrFriendlyName = version: "linux_${builtins.replaceStrings [ "." ] [ "_" ] version}";

      # Returns a list with all aliases of that kernel.
      # We want each kernel to be available as "6.12" and "6.12.x", for example.
      populateAliases =
        {
          kernel,
          aliases ? [ ],
        }:
        let
          version_long = versionToAttrFriendlyName kernel.version;
          version_short = lib.pipe kernel.version [
            lib.splitVersion
            (lib.lists.take 2)
            (lib.concatStringsSep ".")
            versionToAttrFriendlyName
          ];
          allAliases = [
            version_long
            version_short
          ] ++ aliases;
        in
        # New releases have a "6.13" name instead of "6.13.0". Therefore, we
        # remove duplicated entries!
        lib.unique allAliases;

      # Map from alias/name to kernel derivation.
      kernelSourcesAttrs = lib.pipe kernelSourcesList [
        # Populate the aliases
        (map (
          {
            kernel,
            aliases ? [ ],
          }@args:
          {
            inherit kernel;
            aliases = populateAliases args;
          }
        ))
        # Transform to a list of attribute sets where each alias maps to the
        # kernel.
        (lib.concatMap (
          {
            kernel,
            aliases ? [ ],
          }:
          (map (alias: {
            ${alias} = kernel;
          }) aliases)
        ))
        # Now flatten the list of attribute sets into a single attribute set.
        (lib.foldl' (acc: elem: acc // elem) { })
      ];
    in
    kernelSourcesAttrs;

  initrds = {
    minimal = pkgs.callPackage ./build-initrd.nix { };
    default = pkgs.callPackage ./build-initrd.nix {
      additionalPackages = with pkgs; [
        curl
        pciutils
        usbutils
        util-linux # lsblk and more
      ];
    };
  };
}
