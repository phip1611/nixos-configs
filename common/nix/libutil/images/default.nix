{ ansi
, lib
, grub2
, grub2_efi
, limine
, runCommand
, writeShellScriptBin
, writeTextFile
, xorriso
}:

let
  limineX = limine.override ({ enableAll = true; });

  scriptCheckIsMultiboot =
    writeShellScriptBin
      "check-is-multiboot"
      ''
        set -euo pipefail

        export PATH="${lib.makeBinPath [ansi grub2]}:$PATH"

        KERNEL=$1
        MB_VERSION=$2

        if [[ "$MB_VERSION" -eq "1" ]]; then
          grub-file --is-x86-multiboot $KERNEL
        elif [[ "$MB_VERSION" -eq "2" ]]; then
          grub-file --is-x86-multiboot2 $KERNEL
        else
          echo -en "$(ansi bold)$(ansi red)"
          echo -n "Unsupported Multiboot version '$MB_VERSION'!"
          echo -e "$(ansi reset)"
          exit 1
        fi
      '';

  # Creates a limine config for a Multiboot kernel.
  # Reference: https://github.com/limine-bootloader/limine/blob/stable/CONFIG.md
  createLimineMultibootCfg =
    {
      # Multiboot2-compliant kernel.
      kernel
      # Optional cmdline for the kernel. For example "--serial".
    , kernelCmdline ? ""
      # Additional multiboot boot modules.
      # Format: [{file=<derivation or Nix path>; cmdline=<string>;}]
    , bootModules ? [ ]
      # Multiboot version. 1 or 2.
    , multibootVersion ? 2
    }:
    let
      moduleLines = map
        (elem: "    module_path: boot():/${builtins.baseNameOf elem.file}\nMODULE_STRING${elem.cmdline}")
        bootModules;
    in
    (writeTextFile {
      name = "${kernel.name}-limine.conf";
      text = ''
        default_entry: 1
        timeout: 0
        serial: yes
        verbose: yes

        interface_branding: ${kernel.name}

        /Boot ${kernel.name}
            comment: Boot ${baseNameOf kernel} via Multiboot${toString multibootVersion}
            protocol: multiboot${toString multibootVersion}
            kernel_path: boot():/${baseNameOf kernel}
            kernel_cmdline: ${kernelCmdline}
            ${builtins.concatStringsSep "\n" moduleLines}
      '';
    });

  # Creates a hybrid bootable ISO using Limine as bootloader to boot a
  # Multiboot kernel.
  # The image is bootable on legacy x86 BIOS and UEFI platforms.
  createMultibootIso =
    {
      # Multiboot-compliant kernel.
      kernel
      # Optional cmdline for the kernel. For example "--serial".
    , kernelCmdline ? ""
      # Additional multiboot boot modules.
      # Format: [{file=<derivation or Nix path>; cmdline=<string>;}]
    , bootModules ? [ ]
      # Multiboot version. 1 or 2.
    , multibootVersion ? 2
    }@args:
    let
      bootCfg = createLimineMultibootCfg args;
      bootItems = [ kernel ] ++ map (elem: elem.file) bootModules;
      # -f: don't fail if the same file is added multiple times; for example
      #     the kernel itself is passed as boot module. This is sometimes nice
      #     for quick prototyping.
      copyBootitemsLines = map (elem: "cp ${elem} -f filesystem/${builtins.baseNameOf elem}") bootItems;
    in
    runCommand "${kernel.name}-multiboot2-hybrid-iso"
      {
        nativeBuildInputs = [ limineX xorriso scriptCheckIsMultiboot ];
        passthru = { inherit bootItems bootCfg; };
      } ''
      check-is-multiboot ${kernel} ${toString multibootVersion}

      mkdir -p filesystem/EFI/BOOT

      echo "Copying Limine artifacts from '${limineX}':"

      install -m 0644 ${limineX.out}/share/limine/limine-bios.sys filesystem
      install -m 0644 ${limineX.out}/share/limine/limine-bios-cd.bin filesystem
      install -m 0644 ${limineX.out}/share/limine/limine-uefi-cd.bin filesystem
      install -m 0644 ${limineX.out}/share/limine/BOOTIA32.EFI filesystem/EFI/BOOT
      install -m 0644 ${limineX.out}/share/limine/BOOTX64.EFI filesystem/EFI/BOOT

      cp ${bootCfg} filesystem/limine.conf
      ${builtins.concatStringsSep "\n" copyBootitemsLines}

      # The following paths are relative to the root of the baked in file system.
      xorriso -as mkisofs -b limine-bios-cd.bin \
              -no-emul-boot -boot-load-size 4 -boot-info-table \
              --efi-boot limine-uefi-cd.bin \
              -efi-boot-part --efi-boot-image --protective-msdos-label \
              filesystem -o image.iso

      limine bios-install image.iso

      cp image.iso $out
    '';

  # Creates a GRUB config that loads the provided kernel via Multiboot 1 or 2.
  # The kernel must be embedded into the memdisk of GRUB in the /boot directory
  # so that GRUB can load it.
  createGrubMultibootCfg =
    {
      # Multiboot-compliant kernel.
      kernel
      # Optional cmdline for the kernel. For example "--serial".
    , kernelCmdline ? ""
      # Additional multiboot boot modules.
      # Format: [{file=<derivation or Nix path>; cmdline=<string>;}]
    , bootModules ? [ ]
      # Multiboot version. 1 or 2.
    , multibootVersion ? 2
    }:
    let
      bootKeyword =
        if multibootVersion == 1
        then "multiboot" else "multiboot2";
      moduleKeyword =
        if multibootVersion == 1
        then "module" else "module2";
      moduleLines = map
        (elem: "${moduleKeyword} /boot/${builtins.baseNameOf elem.file} ${elem.cmdline}")
        bootModules
      ;
    in
    writeTextFile {
      name = "${kernel.name}-grub.cfg-multiboot${toString multibootVersion}";
      text = ''
        set timeout=0
        menuentry '${baseNameOf kernel}' {
          ${bootKeyword} /boot/${baseNameOf kernel} ${kernelCmdline}
          ${builtins.concatStringsSep "\n" moduleLines}
          boot
        }
      '';
    };

  # Embeds an Multiboot2 ELF binary in a bootable EFI image.
  # The image is based on GRUB.
  # https://uefi.org/specs/UEFI/2.10/02_Overview.html#uefi-images
  #
  # It is recommended to use Multiboot2 here.
  createMultibootEfi =
    {
      # Multiboot-compliant kernel.
      kernel
      # Command line for the kernel.
    , kernelCmdline ? ""
      # Name of the derivation.
    , name ? "${kernel.name}-x86_64-efi"
      # Additional multiboot boot modules.
      # Format: [{file=<derivation or Nix path>; cmdline=<string>;}]
    , bootModules ? [ ]
      # Multiboot version. 1 or 2.
    , multibootVersion ? 2
    }@args:
    let
      grubCfg = createGrubMultibootCfg args;
      target = "x86_64-efi";
      bootItems = [ kernel ] ++ map (elem: elem.file) bootModules;
      # Graft point syntax for GRUB. See `grub-mkstandalone` comments below.
      grubMemdiskIncludeBootitemLines = map
        (elem: "\"/boot/${builtins.baseNameOf elem}=$(realpath ${elem})\"")
        bootItems;
    in
    runCommand name
      {
        nativeBuildInputs = [ grub2_efi scriptCheckIsMultiboot ];
        passthru = { inherit bootItems grubCfg; };
      }
      ''
        set -euo pipefail

        check-is-multiboot ${kernel} ${toString multibootVersion}

        # make a memdisk-based GRUB image
        grub-mkstandalone \
          --format ${target} \
          --output $out \
          --directory ${grub2_efi}/lib/grub/${target} \
          "/boot/grub/grub.cfg=$(realpath ${grubCfg})" \
          ${builtins.concatStringsSep " " grubMemdiskIncludeBootitemLines}
          # ^ This is poorly documented, but the tool allows to specify key-value
          # pairs where the value on the right, a file, will be embedded into the
          # "(memdisk)" volume inside the GRUB image. -> "Graft point syntax"
          #
          # Further, grub-mkstandalone is a beast. It does not report error when
          # files can't be added and drops the failures silently. For example,
          # if a link is put on the right side of the "=" rather than a regular
          # file, the file never appears in the final file.
      '';
in
{
  # For x86 and x86_64.
  x86 = {
    inherit createMultibootIso;
    inherit createMultibootEfi;
  };
}

