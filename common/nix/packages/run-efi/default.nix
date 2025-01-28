{
  ansi,
  argc,
  lib,
  OVMF,
  qemu,
  writeShellScriptBin,
}:

writeShellScriptBin "run-efi" ''
  # The following @-annotations belong to https://github.com/sigoden/argc
  #
  # @describe
  # Convenient helper script to quickly boot a x86_64 EFI image in QEMU.
  #
  # @arg efi-image!
  # Path to the x86_64 EFI image.
  #
  # @arg files*
  # Additional files to put into the volume.
  #
  # @option --qemu-args
  # Additional arguments for QEMU as string. Provide like this:
  # --qemu-args='-debugcon stdio -display none'
  #
  # @flag --no-common-options
  # Don't add common options to QEMU.

  # Bash strict mode.
  set -euo pipefail

  export PATH="${
    lib.makeBinPath ([
      ansi
      argc
      qemu
    ])
  }:$PATH"

  # Do the "argc" magic. Reference: https://github.com/sigoden/argc
  eval "$(argc --argc-eval "$0" "$@")"

  # Sanity check: Is the file valid?
  if [[ "$(file --dereference --brief $argc_efi_image)" != *"EFI"*"x86-64"* ]]; then
    echo -e "$(ansi bold)$(ansi red)Not an EFI x86-64 image!$(ansi reset)"
    exit 1
  fi

  # QEMU/OVMF needs to write the dir (NV VARS). So, this does not live in the
  # Nix store.
  TMPDIR=$(mktemp -d)

  # Volume: Add additional files (such as startup.nsh)
  for file in "''${argc_files[@]}"
  do
    cp -r $file $TMPDIR
  done

  # Volume: Add main file to boot
  mkdir -p "$TMPDIR/EFI/BOOT"
  install -m 0644 "''${argc_efi_image}" "$TMPDIR/EFI/BOOT/BOOTX64.EFI"

  COMMON_ARGS=(
    -nodefaults
    -serial stdio
    -machine q35,accel=kvm
    -no-reboot
  )

  if [ "''${argc_no_common_options:-0}" -eq "1" ]; then
    COMMON_ARGS=()
  fi

  set -x
  qemu-system-x86_64 \
    -bios ${OVMF.fd}/FV/OVMF.fd \
    -drive format=raw,file=fat:rw:$TMPDIR \
    ''${COMMON_ARGS[*]} \
    ''${argc_qemu_args[*]:-}; rm -rf $TMPDIR
''
