# Test this using:
# nix develop --command bash -c 'rm -rf dir1 dir2 && mkdir dir1 && echo "hello" > dir1/hello.txt && echo "hello2" > dir1/hello2.txt && cp -r dir1 dir2 && cp dir2/hello.txt dir2/hello3.txt && echo "foobar" > dir2/hello.txt && keep-directory-diff dir1 dir2'

{
  lib,
  writeShellScriptBin,
  # runtime deps
  ansi,
  argc,
  fd,
}:

writeShellScriptBin "keep-directory-diff" ''
  # The following @-annotations belong to https://github.com/sigoden/argc
  #
  # @describe
  # This script takes two directories. The first directory is the base source.
  # The second is the base source plus or minus potentially additional/modified
  # sources. It removes all files from the second directory that are unchanged
  # regarding the first directory. The use case is to get the actual difference
  # that preparation scripts of a source tree cause, such as through downloading
  # certain resources into the tree.
  #
  # Only file content is checked, not file attributes. Symlinks are ignored.
  #
  # @arg base! Base directory
  # Path to source directory
  # @arg target! Target directory
  # Path to target directory. This directory is modified.

  # Bash strict mode.
  set -eou pipefail

  export PATH="${
    lib.makeBinPath ([
      ansi
      argc
      fd
    ])
  }:$PATH"

  # Do the "argc" magic. Reference: https://github.com/sigoden/argc
  eval "$(argc --argc-eval "$0" "$@")"

  # Find directories and regular files, don't follow symlinks.
  readarray -d "" BASE_FILES < <(cd "$argc_base" && fd --unrestricted --print0 --type file)
  TARGET_DIR=$(realpath "$argc_target")

  for FILE in "''${BASE_FILES[@]}"; do
    # Check if the content of the file was changed.
    TARGET_FILE="$argc_target/$FILE"
    FILE="$argc_base/$FILE"
    echo -e "base file  : $(ansi bold)$FILE$(ansi reset)"
    echo -e "target file: $(ansi bold)$TARGET_FILE$(ansi reset)"
    if [ -L "$TARGET_FILE" ]; then
      echo -e "  Skipping   $(ansi bold)$TARGET_FILE$(ansi reset) as it is a symlink."
    elif [ ! -f "$TARGET_FILE" ]; then
      echo -e "  Skipping   $(ansi bold)$TARGET_FILE$(ansi reset) as it doesn't exist."
    # A symlinked parent directory may point outside of the target directory.
    elif [[ "$(realpath "$TARGET_FILE")" != "$TARGET_DIR"/* ]]; then
      echo -e "  Skipping   $(ansi bold)$TARGET_FILE$(ansi reset) as it is outside of the target directory."
    elif cmp -s "$FILE" "$TARGET_FILE"; then
      echo -e "  Removing   $(ansi bold)$TARGET_FILE$(ansi reset) as it hasn't changed."
      rm -f "$TARGET_FILE"
    else
      echo -e "  Keeping $(ansi bold)$TARGET_FILE$(ansi reset) as it was modified."
    fi
  done
''
