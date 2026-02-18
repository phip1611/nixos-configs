#!/usr/bin/env bash

# This script backups `~/.zsh_history` to `~/.local/share/zsh-history-backup` or
# restores it from there, if necessary.
#
# It does so on every invocation. This helps to workaround cases where ZSH
# suddenly truncates the history file, which I experiences once every ~3 months.
#
# After restoring, only new zsh sessions will read the history from the new
# file, or the history needs to be explicitly imported using the shell built-in
# `fc`.

set -euo pipefail

# TODO switch to `$(zsh -ic 'echo $HISTFILE')`?
HIST_FILE="$HOME/.zsh_history"
BACKUP_DIR="$HOME/.local/share/zsh-history-backup/backups"
BACKUP_FILE_LATEST="$BACKUP_DIR/.zsh_history.latest"
TIMESTAMP="$(date --iso-8601=seconds)"

# Creates a backup file.
fn_backup_file() {
  mkdir -p "$BACKUP_DIR"
  if [ -f "$BACKUP_FILE_LATEST" ]; then
    mv -f "$BACKUP_FILE_LATEST" "$BACKUP_FILE_LATEST.old"
  fi
  # Keep freshest file in clear text
  cp "$HIST_FILE" "$BACKUP_FILE_LATEST"
  chmod -w "$BACKUP_FILE_LATEST"
  # Also archive it (compressed)
  zstd  "$BACKUP_FILE_LATEST" --compress -17 -o "$BACKUP_DIR/$TIMESTAMP-zsh-history.zstd" 2>/dev/null
  chmod -w "$BACKUP_DIR/$TIMESTAMP-zsh-history.zstd"
  rm -f "$BACKUP_FILE_LATEST.old"
}

# Deletes outdated backup files from $BACKUP_DIR according:
# 1. Keep all backups from the past 2 days.
# 2. For older backups, keep only one per month (the oldest backup for that
#    month).
#
# Requirements:
#   - Backup filenames must follow the format: YYYY-MM-DDTHH:MM:SS+TZ-zsh-history.zstd
#   - Script will fail if a filename cannot be parsed into a valid timestamp.
#   - Operates in-place, deleting files that do not meet the retention criteria.
fn_delete_outdated() {
    local now_ts file_ts_sec age month_key
    local keep_last_days=2
    declare -A seen_months=()

    now_ts=$(date +%s)

    # Iterate all backup files, sorted oldest first
    mapfile -t backup_files < <(ls -1 "$BACKUP_DIR"/*.zstd 2>/dev/null | sort)

    for file in "${backup_files[@]}"; do
        local file_base
        file_base=$(basename "$file")

        # Extract timestamp: YYYY-MM-DDTHH:MM:SS
        local file_ts
        file_ts=$(echo "$file_base" | cut -d'-' -f1-3 | sed 's/T/ /')

        # Convert to epoch seconds; fail if invalid
        file_ts_sec=$(date -d "$file_ts" +%s)

        # Age in seconds
        age=$(( now_ts - file_ts_sec ))

        if [ "$age" -le $((keep_last_days*24*60*60)) ]; then
            # Keep everything from the last 2 days
            continue
        fi

        # Key for the month, e.g., "2026-02"
        month_key=$(date -d "@$file_ts_sec" +%Y-%m)

        # If we already kept a file for this month, delete this one
        if [ -n "${seen_months[$month_key]+x}" ]; then
            echo "Deleting outdated backup: $file"
            rm -f "$file"
        else
            # Keep the first encountered backup for this month
            seen_months[$month_key]=1
        fi
    done
}

fn_restore_backup() {
  rm -f "$HIST_FILE"
  cp "$BACKUP_FILE_LATEST" "$HIST_FILE"
  chmod u+w "$HIST_FILE"
}

# Checks if we need to restore the backup.
fn_need_restore() {
  local RET_NEED_BACKUP_RESTORE=0
  local RET_NO_BACKUP_RESTORE=1
  local backup_size=0
  local current_size=0

  # Get the maximum lines the ZSH history file can have.
  # We start an interactive shell to ensure that zsh sources all its
  # configuration files properly.
  # limit=$(zsh -ic 'echo $SAVEHIST')

  # Check that current file exists.
  if [ -f "$HIST_FILE" ]; then
    current_size=$(wc -l < "$HIST_FILE")
  fi

  # Check that backup file exists.
  if [ -f "$BACKUP_FILE_LATEST" ]; then
    backup_size=$(wc -l < "$BACKUP_FILE_LATEST")
  fi

  # We only need to restore the file when the file was truncated.
  echo "current history size=$current_size"
  echo "backup history size =$backup_size"
  if [ "$current_size" -lt "$backup_size" ]; then
      return "$RET_NEED_BACKUP_RESTORE"
  else
      return "$RET_NO_BACKUP_RESTORE"
  fi
}

fn_main() {
  if fn_need_restore; then
    echo "⚠️ The ZSH history file seems to have been truncated; restoring backup"
    fn_restore_backup
    echo "✅ Backup restored in '$HIST_FILE'. Please reload/restart your ZSH shells"
  else
    echo "✅ Backing up history file '$HIST_FILE' to '$BACKUP_DIR'"
    if [ -f "$HIST_FILE" ]; then
      fn_backup_file
    fi
  fi
  fn_delete_outdated
}

fn_main
