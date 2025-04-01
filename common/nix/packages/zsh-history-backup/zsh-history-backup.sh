#!/usr/bin/env bash

# This script backups `~/.zsh_history` to `~/.zsh_history.backup` or restores it
# from there, if necessary.
#
# It does so on every invocation. This helps to workaround cases where ZSH
# suddenly truncates the history file, which I experiences once every ~4-6
# months.
#
# Only new zsh sessions will read the history from the new file, or the history
# needs to be explicitly imported using the shell built-in `fc`.

set -euo pipefail

# TODO switch to `$(zsh -ic 'echo $HISTFILE')`?
HIST_FILE="$HOME/.zsh_history"
BACKUP_FILE="$HIST_FILE.backup"

# Creates a backup file.
fn_backup_file() {
  if [ -f "$BACKUP_FILE" ]; then
    mv "$BACKUP_FILE" "$BACKUP_FILE.old"
  fi
  cp "$HIST_FILE" "$BACKUP_FILE"
  rm -f "$BACKUP_FILE.old"
}

fn_restore_backup() {
  rm -f "$HIST_FILE"
  cp "$BACKUP_FILE" "$HIST_FILE"
}

# Checks if we need to restore the backup.
fn_need_restore() {
  local WAS_TRUNCATED_THRESHOLD=100
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
  if [ -f "$BACKUP_FILE" ]; then
    backup_size=$(wc -l < "$BACKUP_FILE")
  fi

  # We only need to restore the file when the file was truncated.
  echo "current history size=$current_size"
  echo "backup history size =$backup_size"
  if [ "$current_size" -lt "$WAS_TRUNCATED_THRESHOLD" ] && [ "$current_size" -lt "$backup_size" ]; then
      return "$RET_NEED_BACKUP_RESTORE"
  else
      return "$RET_NO_BACKUP_RESTORE"
  fi
}

fn_main() {
  if fn_need_restore; then
    echo "⚠️ The history files seems to have been truncated; restoring backup"
    fn_restore_backup
    echo "✅ Backup restored in '$HIST_FILE'"
  else
    echo "✅ Backing up history file '$HIST_FILE' to '$BACKUP_FILE'"
    if [ -f "$HIST_FILE" ]; then
      fn_backup_file
    fi
  fi
}

fn_main
