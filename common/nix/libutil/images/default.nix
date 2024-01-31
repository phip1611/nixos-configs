{ ansi
, lib
, grub2
, grub2_efi
, writeTextFile
, runCommand
, writeShellScriptBin
, xorriso
}:

let
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
    (writeTextFile {
      name = "${kernel.name}-grub.cfg-multiboot${toString multibootVersion}";
      text = ''
        set timeout=0
        menuentry '${baseNameOf kernel}' {
          ${bootKeyword} /boot/${baseNameOf kernel} ${kernelCmdline}
          ${builtins.concatStringsSep "\n" moduleLines}
          boot
        }
      '';
    }).overrideAttrs {
      passthru = { inherit multibootVersion; };
    };

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

  # Embeds an Multiboot (1 or 2) ELF binary in a legacy-bootable ISO image.
  # The image is based on GRUB.
  createBootableMultibootIso =
    {
      # Multiboot-compliant kernel.
      kernel
      # Command line for the kernel.
    , kernelCmdline ? ""
      # Name of the derivation.
    , name ? "${kernel.name}-x86-iso"
      # Additional multiboot boot modules.
      # Format: [{file=<derivation or Nix path>; cmdline=<string>;}]
    , bootModules ? [ ]
      # Multiboot version. 1 or 2.
    , multibootVersion ? 2
    }@args:
    let
      grubCfg = createGrubMultibootCfg args;
      bootItems = [ kernel ] ++ map (elem: elem.file) bootModules;
      # -f: don't fail if the same file is added multiple times; for example
      #     the kernel itself is passed as boot module. This is sometimes nice
      #     for quick prototyping.
      copyBootitemsLines = map (elem: "cp ${elem} -f filesystem/boot/${builtins.baseNameOf elem}") bootItems;
    in
    runCommand name
      {
        nativeBuildInputs = [ grub2 xorriso scriptCheckIsMultiboot ];
        passthru = { inherit bootItems grubCfg; };
      }
      ''
        set -euo pipefail

        check-is-multiboot ${kernel} ${toString multibootVersion}

        mkdir -p filesystem/boot/grub
        cp ${grubCfg} filesystem/boot/grub/grub.cfg
        ${builtins.concatStringsSep "\n" copyBootitemsLines}

        grub-mkrescue -d ${grub2}/lib/grub/i386-pc/ -o "$out" filesystem
      '';

  # Embeds an Multiboot2 ELF binary in a bootable EFI image.
  # The image is based on GRUB.
  # https://uefi.org/specs/UEFI/2.10/02_Overview.html#uefi-images
  #
  # It is recommended to use Multiboot2 here.
  createBootableMultibootEfi =
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
    inherit createBootableMultibootIso;
    inherit createBootableMultibootEfi;
  };
}

