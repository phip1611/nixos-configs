#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# FTPS Backup using lftp. Parallel recursive downloads of an FTP directory using
# explicit FTP over TLS. The downloaded archive is compressed as tar.zst (zstd).
# The underlying lftp command is smart enough to continue a mirroring when some
# of the files are already locally available.
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
# @flag --keep
# Keep the downloaded directory (next to the compressed archive).

set -euo pipefail

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

# Downloads every file into target/source
for directory in "${argc_source[@]}"; do
  # realpath: get rid of unnecessary trailing "/" or "//"
  target=$(realpath "$argc_target/$directory")
  mkdir -p $target
  echo -e "$(ansi bold)Mirroring '$directory' from '$argc_host' to '$target' using explicit FTPS$(ansi reset)"

  # Use explicit FTP. The user authentication details are exchanged after the
  # TLS connection is established.
  lftp -u $argc_user,$argc_pass -e "\
  	set ftp:ssl-force true \
  	set ftp:ssl-protect-data true \
  	" $argc_host <<EOF
  mirror --continue --parallel=$argc_connections --verbose=3 $directory $target
  quit
EOF
done

COMPRESSED="$argc_target".tar.zst
echo -e "$(ansi bold)Compressing as '$COMPRESSED$(ansi reset)'"
rm -f "$COMPRESSED"
tar -acf "$COMPRESSED" "$argc_target"

if [ -z "${argc_keep:-}" ]; then
  echo -e "$(ansi bold)Removing directory '$argc_target$(ansi reset)'"
  rm -r "$argc_target"
else
  echo -e "$(ansi bold)Keeping '$argc_target$(ansi reset)'"
fi

