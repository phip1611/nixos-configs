#!/usr/bin/env bash

# @describe
# Normalizes file permissions of user files, which means that recursively all
# files are set to 0644 and all directories to 0755. One use case is to
# normalize the permissions after you messed with file permissions or copied
# files from another user's home directory to your directory.
#
# Depending on what the initial situation is like, you may have to run the
# utility with sudo. Use "--user" then!
#
# Links are ignored and not followed.
#
# @option --user=$(whoami)    New user name.
# @option --group=users       New group name.
# @option --directory=$(pwd)  Working directory
# @flag --dry-run     Perform a dry run. Just print meta info.

set -euo pipefail

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

DEFAULT_FILE_PERMISSION="0644"
DEFAULT_DIR_PERMISSION="0755"

ARG_USER=$argc_user
ARG_GROUP=$argc_group
ARG_DIRECTORY=$argc_directory
ARG_DRY_RUN="${argc_dry_run:-0}" # "0" or "1"

# Replace magic arg values.

if [ "$argc_user" = "\$(whoami)" ];
then
  ARG_USER=$(whoami)
fi

if [ "$argc_directory" = "\$(pwd)" ];
then
  ARG_DIRECTORY=$(pwd)
fi

echo -ne "$(ansi bold)User     : $(ansi reset)"
echo "$ARG_USER"
echo -ne "$(ansi bold)Group    : $(ansi reset)"
echo "$ARG_GROUP"
echo -ne "$(ansi bold)Directory: $(ansi reset)"
echo "$ARG_DIRECTORY"

if [ $ARG_DRY_RUN -eq 1 ];
then
  echo "Dry run. Do nothing."
  exit 0
fi

chgrp -R "$ARG_GROUP" "$ARG_DIRECTORY"
chown -R "$ARG_USER" "$ARG_DIRECTORY"

fd --type=directory --exec-batch sh -c "chmod $DEFAULT_DIR_PERMISSION {}" "$ARG_DIRECTORY"
fd --type=file --exec-batch sh -c "chmod $DEFAULT_FILE_PERMISSION {}" "$ARG_DIRECTORY"
