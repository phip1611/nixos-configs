{ pkgs }:

let
  lib = pkgs.lib;

  # Attribute set with minimal Linux kernel in different versions.
  kernels =
    let
      # List of kernel source trees.
      kernelSourcesList = lib.lists.unique [
        # Current stable kernel
        ({
          kernelSrc = pkgs.linux;
          aliases = [
            "stable"
            "lts"
          ];
        })
        # Latest kernel
        ({
          kernelSrc = pkgs.linux_latest;
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
      aliasesToMinimalKernelAttrs = lib.pipe kernelSourcesList [
        # Build the minimal kernel
        (map (
          {
            kernelSrc,
            aliases ? [ ],
          }:
          {
            inherit aliases;
            kernel = import ./build-kernel.nix {
              inherit (pkgs) lib linuxKernel stdenv;
              inherit kernelSrc;
            };
          }
        ))
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
    aliasesToMinimalKernelAttrs;

  initrds =
    let
      buildInitrd = pkgs.callPackage ./build-initrd.nix;
      # Something overloads packages from busybox and break the init shell.
      # Therefore, we use a reduced set.
      linux-util-reduced =
        let
          components = [
            "lsblk"
            "lscpu"
          ];
          pkg = pkgs.util-linux;
          cpLines = lib.pipe components [
            (map (component: "cp ${pkg}/bin/${component} $out/bin"))
            (lib.concatStringsSep "\n")
          ];
        in
        pkgs.runCommandLocal "${pkg.name}-reduced" { } ''
          mkdir -p $out/bin
          ${cpLines}
        '';
    in
    {
      minimal = buildInitrd { };
      default = buildInitrd {
        additionalPackages = with pkgs; [
          curl
          linux-util-reduced
          msr-tools
          pciutils
          strace
          stress
          usbutils
        ];
      };
    };
in
{
  inherit kernels;
  # initrds enriched with embedded kernels and initrds.
  initrds = initrds // {
    # initrd with VMMs and bootfiles for nested virtualization.
    vmms = initrds.default.override (old: {
      additionalPackages =
        (old.additionalPackages or [ ])
        ++ (with pkgs; [
          cloud-hypervisor
          # Very big; long build process and unpacking during runtime
          # qemu
        ]);

      # Add some ready to use bootfiles for Cloud Hypervisor.
      # They can be used like this:
      #
      # $ cloud-hypervisor \
      #     --kernel "/etc/bootitems/kernel/bzImage" \
      #     --cmdline "console=ttyS0" \
      #     --initramfs "/etc/bootitems/initrd/initrd" \
      #     --serial "tty" \
      #     --console "off" \
      #     --memory size=1G
      additionalFiles = (old.additionalFiles or [ ]) ++ [
        {
          symlink = "/etc/bootitems/initrd";
          object = initrds.default;
        }
        {
          symlink = "/etc/bootitems/kernel";
          object = kernels.stable;
        }
      ];
    });
  };
}
