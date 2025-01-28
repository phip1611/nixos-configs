{
  writeShellScriptBin,
  qemu,
  OVMF,
}:

# Wrapper around "qemu-system-x86_64" that uses OVMF as UEFI firmware.
writeShellScriptBin "qemu-uefi" ''
  # Bash strict mode.
  set -euo pipefail

  set -x
  exec ${qemu}/bin/qemu-system-x86_64 \
        -bios ${OVMF.fd}/FV/OVMF.fd \
        "$@"
''
