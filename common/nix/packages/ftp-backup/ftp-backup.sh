#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# FTPS Backup using lftp. Parallel recursive downloads of an FTP directory using
# explicit FTP over TLS. The downloaded archive is compressed as tar.zst (zstd).
# The underlying lftp command is smart enough to continue a mirroring when some
# of the files are already locally available. When the target directory is
# reused, only new and changed files are downloaded, and files that were
# deleted on the remote are deleted locally.
# The password SHOULD be passed as FTP_PASS environment variable so that it
# doesn't appear in the process list.
#
# Example invocation:
#
# $ ftp-backup --host w1234.ftphost.com --user w1234 --pass 'password123!' logs automated-backups --target local-backup-dir --keep
#
#
# @option --host=$FTP_HOST Host Name (must match certificate)
# @option --user=$FTP_USER FTP username
# @option --pass=$FTP_PASS FTP password
# @option --connections=10
# Maximum amount of parallel connections (for quicker downloads). Some
# web-hosting providers limit this to 10 and terminate all sessions once this
# limit is exceeded. So be conservative. Some other hosters may reject further
# requests but lftp can cope with that.
# @arg source*
# Directory to backup on remote. "/" by default. Can also be "foo/bar bar".
# @option --target=<yyyy-mm-dd_ftp-backup>
# Target directory on local machine.
# @option --archive=<target>.tar.zst
# Path of the compressed archive.
# @flag --keep
# Keep the downloaded directory, e.g., to reuse it for the next backup.

set -euo pipefail

# Backups often contain secrets, such as database credentials of a website.
umask 077

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

argc_source="${argc_source:-/}"
# Replace with sane defaults.
if [ "$argc_host" = '$FTP_HOST' ]; then
  argc_host=$FTP_HOST
fi
if [ "$argc_user" = '$FTP_USER' ]; then
  argc_user=$FTP_USER
fi
if [ "$argc_pass" = '$FTP_PASS' ]; then
  argc_pass=$FTP_PASS
fi
if [ "$argc_target" = "<yyyy-mm-dd_ftp-backup>" ]; then
  argc_target=$(date +%Y-%m-%d_%H%M)_ftp-backup
fi
if [ "$argc_archive" = "<target>.tar.zst" ]; then
  argc_archive="$argc_target".tar.zst
fi

# Downloads every file into target/source
for directory in "${argc_source[@]}"; do
  # realpath: get rid of unnecessary trailing "/" or "//". The target doesn't
  # exist yet.
  target=$(realpath -m "$argc_target/$directory")
  mkdir -p "$target"
  echo -e "$(ansi bold)Mirroring '$directory' from '$argc_host' to '$target' using explicit FTPS$(ansi reset)"

  # Use explicit FTP. The user authentication details are exchanged after the
  # TLS connection is established. The password goes via the environment, so
  # that it doesn't appear in the process list. Unreachable hosts fail after a
  # few minutes, while lftp's defaults (5m timeout, 1000 retries) would block
  # the backup for hours.
  #
  # lftp only connects for the first command that needs a connection, so the
  # settings apply before the login.
  LFTP_PASSWORD=$argc_pass lftp --env-password -u "$argc_user" "$argc_host" <<EOF
  set ftp:ssl-force true
  set ftp:ssl-protect-data true
  set net:timeout 30
  set net:max-retries 3
  mirror --continue --delete --parallel=$argc_connections --verbose=3 "$directory" "$target"
  quit
EOF
done

COMPRESSED="$argc_archive"
echo -e "$(ansi bold)Compressing as '$COMPRESSED$(ansi reset)'"
rm -f "$COMPRESSED"
tar -acf "$COMPRESSED" "$argc_target"
# Don't trust a backup that can't be read back.
echo -e "$(ansi bold)Verifying '$COMPRESSED'$(ansi reset)"
zstd -q --test "$COMPRESSED"

if [ -z "${argc_keep:-}" ]; then
  echo -e "$(ansi bold)Removing directory '$argc_target$(ansi reset)'"
  rm -r "$argc_target"
else
  echo -e "$(ansi bold)Keeping '$argc_target$(ansi reset)'"
fi
