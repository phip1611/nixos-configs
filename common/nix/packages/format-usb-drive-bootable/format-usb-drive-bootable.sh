#!/usr/bin/env bash

# Interactively prepare a removable USB drive for EFI boot files.

set -Eeuo pipefail

readonly PROGRAM_NAME="format-usb-drive-bootable"
readonly DEFAULT_VOLUME_LABEL="USB"
# Nix-store binaries cannot be setuid; use NixOS's system sudo wrapper instead.
readonly SUDO_BIN="/run/wrappers/bin/sudo"

selected_drive=""

use_color() {
  [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]
}

style() {
  local code="$1"

  if use_color; then
    printf '\033[%sm' "$code"
  fi
}

reset_style() {
  if use_color; then
    printf '\033[0m'
  fi
}

heading() {
  printf '\n%s%s%s\n' "$(style '1;36')" "$1" "$(reset_style)"
  printf '%s\n' "$(printf '%*s' "${#1}" '' | tr ' ' '=')"
}

info() {
  printf '%sINFO%s  %s\n' "$(style '1;34')" "$(reset_style)" "$*"
}

warning() {
  printf '%sWARN%s  %s\n' "$(style '1;33')" "$(reset_style)" "$*" >&2
}

error() {
  printf '%sERROR%s %s\n' "$(style '1;31')" "$(reset_style)" "$*" >&2
}

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME [--name LABEL]

Interactively prepare a removable USB drive for EFI boot files. The selected
drive is reformatted as GPT with one FAT32 partition and an
EFI/BOOT directory. This permanently destroys all data on the selected drive.

Options:
  -n, --name LABEL  FAT32 volume label (default: $DEFAULT_VOLUME_LABEL)
  -h, --help        Show this help text
EOF
}

is_valid_label() {
  local label="$1"

  [[ "$label" =~ ^[A-Za-z0-9_-]{1,11}$ ]]
}

# Verify that the selected path is still a removable whole disk before writing.
is_removable_disk() {
  local drive="$1"

  [[ "$(lsblk --noheadings --raw --nodeps --output TYPE,RM "$drive")" == "disk 1" ]]
}

# List only removable whole disks in a tab-separated format for fzf.
candidate_drives() {
  lsblk --noheadings --output PATH,RM,TYPE,SIZE,MODEL \
    | awk '
        $2 == 1 && $3 == "disk" {
          path = $1;
          size = $4;
          $1 = $2 = $3 = $4 = "";
          sub(/^[[:space:]]+/, "");
          printf "%s\t%s\t%s\n", path, size, ($0 == "" ? "unknown" : $0);
        }
      '
}

# Let fzf select one of the removable disks without parsing its display text.
choose_drive() {
  local candidates
  local selected

  candidates=$(candidate_drives)
  if [[ -z "$candidates" ]]; then
    error "No removable whole disks were found."
    exit 1
  fi

  selected=$(printf '%s\n' "$candidates" \
    | fzf --ansi --height=16 --layout=reverse --border=rounded \
        --header='Select a removable USB drive — Ctrl-C/Esc cancels' \
        --prompt='USB drive > ' --delimiter=$'\t' --with-nth=1,2,3) \
    || return 1

  selected_drive="${selected%%$'\t'*}"
}

# Show the exact partitions and mounts that will be affected by formatting.
show_affected_partitions() {
  printf '\n'
  lsblk --output PATH,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$1"
}

# Unmount only filesystems that belong to partitions on the selected drive.
unmount_drive_partitions() {
  local drive="$1"
  local mountpoint

  while IFS= read -r mountpoint; do
    [[ -z "$mountpoint" ]] && continue
    info "Unmounting $mountpoint"
    "$SUDO_BIN" -- umount "$mountpoint"
  done < <(lsblk --list --noheadings --paths --output TYPE,MOUNTPOINTS "$drive" \
    | awk '$1 == "part" && $2 != "" { print $2 }')
}

# Find the one partition created by the preceding parted command.
partition_path() {
  local drive="$1"
  local -a partitions

  mapfile -t partitions < <(
    lsblk --noheadings --list --paths --output PATH,TYPE "$drive" \
      | awk '$2 == "part" { print $1 }'
  )

  if (( ${#partitions[@]} != 1 )); then
    error "Expected one new partition on $drive, found ${#partitions[@]}."
    return 1
  fi

  printf '%s\n' "${partitions[0]}"
}

volume_label="$DEFAULT_VOLUME_LABEL"

while (( $# > 0 )); do
  case "$1" in
    -n | --name)
      if (( $# < 2 )); then
        error "Missing value for $1."
        usage >&2
        exit 2
      fi
      volume_label="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if ! is_valid_label "$volume_label"; then
  error "The volume label must be 1-11 characters of A-Z, a-z, 0-9, _ or -."
  exit 2
fi

if [[ ! -t 0 || ! -t 1 ]]; then
  error "An interactive terminal is required."
  exit 2
fi

if [[ ! -x "$SUDO_BIN" || ! -u "$SUDO_BIN" ]]; then
  error "The NixOS setuid sudo wrapper is unavailable: $SUDO_BIN"
  exit 1
fi

heading "Format USB Drive for EFI Boot"
info "This creates one FAT32 partition with EFI/BOOT/."
warning "All data on the selected drive will be permanently destroyed."

if ! choose_drive; then
  info "Cancelled; no drive was modified."
  exit 0
fi
drive="$selected_drive"

if ! is_removable_disk "$drive"; then
  error "$drive is no longer an available removable whole disk."
  exit 1
fi

safe_label=$(printf '%s' "$volume_label" | tr '[:upper:]' '[:lower:]')
user_uid=$(id -u)
user_gid=$(id -g)
if [[ -d /mnt ]]; then
  mount_parent=/mnt
else
  mount_parent=/tmp/mnt
fi
mount_dir="$mount_parent/$PROGRAM_NAME-$safe_label"

if [[ -L "$mount_dir" ]] || mountpoint --quiet "$mount_dir" 2>/dev/null; then
  error "The planned mount point is already in use: $mount_dir"
  exit 1
fi

heading "Selected Drive"
printf '  Drive:       %s\n' "$drive"
printf '  Volume label: %s\n' "$volume_label"
printf '  Mount point:  %s\n' "$mount_dir"
printf '  Affected partitions:\n'
show_affected_partitions "$drive"

printf '\n'
read -r -p "Do you really want to reformat $drive [y/N] " confirmation
if [[ ! "$confirmation" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  info "Cancelled; no drive was modified."
  exit 0
fi

if ! is_removable_disk "$drive"; then
  error "The selected drive changed after confirmation; no changes were made."
  exit 1
fi

info "Sudo is requested only for the required privileged operations below."
unmount_drive_partitions "$drive"
info "Creating a GPT partition table and FAT32 partition."
"$SUDO_BIN" -- parted --script --align optimal "$drive" \
  mklabel gpt \
  mkpart BOOT fat32 1MiB 100%
"$SUDO_BIN" -- partprobe "$drive"
udevadm settle

partition=$(partition_path "$drive")
info "Formatting $partition as FAT32 with label $volume_label."
"$SUDO_BIN" -- mkfs.fat -F 32 -n "$volume_label" "$partition"

info "Mounting the new partition at $mount_dir."
"$SUDO_BIN" -- mkdir -p "$mount_dir"
"$SUDO_BIN" -- mount -o "uid=$user_uid,gid=$user_gid,umask=022" "$partition" "$mount_dir"
mkdir -p "$mount_dir/EFI/BOOT"

heading "✅ Formatted Successfully"
printf 'You can now place an EFI file in:\n\n'
printf '  %s/EFI/BOOT/\n\n' "$mount_dir"
printf 'For x86_64 removable-media boot, use BOOTX64.EFI in that directory.\n'
