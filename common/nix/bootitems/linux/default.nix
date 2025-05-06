{
  pkgs,
  libutil,
}:

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
          ]
          ++ aliases;
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

  initrds' =
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

      commonConveniencePackages = with pkgs; [
        curl
        htop
        linux-util-reduced
        msr-tools
        pciutils
        strace
        stress-ng
        usbutils
      ];
    in
    {
      minimal = buildInitrd { };
      default = buildInitrd {
        additionalPackages = commonConveniencePackages;
      };
    };

  # initrds that reference/extend other base initrds.
  initrds = initrds' // {
    # initrd with VMMs and bootfiles for nested virtualization.
    vmms = initrds'.default.override (old: {
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
          target = "/etc/bootitems/initrd";
          source = initrds.minimal;
        }
        {
          target = "/etc/bootitems/kernel";
          source = kernels.stable;
        }
      ];
      initScript = (old.initScript or "") + ''
        alias run_chv='cloud-hypervisor \
          --kernel "/etc/bootitems/kernel/bzImage" \
          --cmdline "console=ttyS0" \
          --initramfs "/etc/bootitems/initrd/initrd" \
          --serial "tty" \
          --console "off" \
          --memory size=1G'
      '';
    });
  };

  # Combines all kernels in a single derivation as vmlinux and bzImage with a
  # file name reflecting the version number (x.y or x.y.z).
  #
  # The attribute name corresponds to the file name.
  kernelsCombined =
    let
      # Function that extracts bzImage and vmlinux from a kernel drv into a new
      # drv.
      kernelDrvToArtifacts =
        name: kernel:
        let
          bzImage = "${kernel}/bzImage";
          vmlinux = "${libutil.builders.extractVmlinux kernel}/vmlinux";
        in
        pkgs.runCommand "${name}-artifacts" { } ''
          mkdir $out
          cp ${bzImage} $out/${name}.bzImage
          cp ${vmlinux} $out/${name}.vmlinux
        '';
    in
    lib.pipe kernels [
      (lib.mapAttrsToList (name: kernel: kernelDrvToArtifacts name kernel))
      (
        drvs:
        pkgs.symlinkJoin {
          name = "kernels-combined";
          paths = drvs;
        }
      )
    ];

  # Combines all initrds in a single derivation.
  #
  # The attribute name corresponds to the file name.
  initrdsCombined =
    let
      # Function that extracts bzImage and vmlinux from a kernel drv into a new
      # drv.
      renameInitrd =
        name: initrd:
        pkgs.runCommand "${name}-artifacts" { } ''
          mkdir $out
          cp ${initrd}/initrd $out/initrd_${name}
        '';
    in
    lib.pipe initrds [
      (lib.mapAttrsToList (name: initrd: renameInitrd name initrd))
      (
        drvs:
        pkgs.symlinkJoin {
          name = "initrds-combined";
          paths = drvs;
        }
      )
    ];
in
{
  inherit
    kernels
    kernelsCombined
    initrdsCombined
    initrds
    ;
}
