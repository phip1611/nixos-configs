#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# Renames photos in a directory so that their alphabetical order equals their
# chronological order. The photos are sorted by their EXIF creation date
# ("Aufnahmedatum", i.e., the DateTimeOriginal tag) and then numbered
# sequentially using a name template:
#
#   $ rename-photos-by-date Kanada
#   IMG_4711.JPG  -> Kanada (001).jpg
#   whatever.heic -> Kanada (002).heic
#
# The amount of leading zeroes is chosen so that all numbers have the same
# width (at least three digits).
#
# Only regular files directly inside the given directory are considered, and
# only those with a jpg, jpeg, or heic extension (case-insensitive). Everything
# else is ignored. Photos without an EXIF creation date are ignored as well.
#
# The renaming is conflict-free. It is performed in two phases (via temporary
# names), so that photos already occupying a target name - including swaps such
# as "a.jpg" <-> "b.jpg" - are handled correctly. If an ignored file occupies a
# target name, nothing is renamed at all.
#
# If a previous run was interrupted, photos may be left behind under temporary
# names. This is detected and reported, and nothing is renamed until it is
# resolved. Use "--recover" for that: the leftovers are photos, not garbage, so
# they are not deleted but taken into the new attempt, where they get their
# proper name like every other photo. Recovery only happens if every leftover
# is still a readable photo with an EXIF creation date.
#
# @arg name!                  Name template, such as "Kanada".
# @option --directory=$(pwd)  Directory holding the photos.
# @flag --dry-run             Only print what would be done.
# @flag --yes                 Do not ask for confirmation.
# @flag --recover             Take leftovers of an interrupted run into this run.

set -euo pipefail

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

ARG_NAME="$argc_name"
ARG_DIRECTORY="$argc_directory"
ARG_DRY_RUN="${argc_dry_run:-0}" # "0" or "1"
ARG_YES="${argc_yes:-0}"         # "0" or "1"
ARG_RECOVER="${argc_recover:-0}" # "0" or "1"

# Replace magic arg values.
if [ "$ARG_DIRECTORY" = "\$(pwd)" ]; then
  ARG_DIRECTORY=$(pwd)
fi

# Photo extensions we care about (matched case-insensitively).
PHOTO_EXTENSIONS=(jpg jpeg heic)
# EXIF tag holding the creation date ("Aufnahmedatum").
EXIF_DATE_TAG="DateTimeOriginal"
# Minimum width of the number in the new file names.
MIN_NUMBER_WIDTH=3
# Temporary names used during the two-phase renaming look like
# ".rename-photos-by-date.<pid>.<index>.<extension>.tmp". The extension is part
# of the name so that an interrupted run can be recovered without guessing.
TMP_PREFIX=".rename-photos-by-date."
TMP_SUFFIX=".tmp"
# Matches the temporary names of any run, not just of this one.
TMP_REGEX='^\.rename-photos-by-date\.[0-9]+\.[0-9]+\.[A-Za-z0-9]+\.tmp$'

# The escape sequences are resolved once. Calling "ansi" per output line would
# fork a process per line, which dominates the runtime for a few hundred
# photos.
BOLD=$(ansi bold)
RED=$(ansi red)
YELLOW=$(ansi yellow)
GREEN=$(ansi green)
RESET=$(ansi reset)

if [ ! -d "$ARG_DIRECTORY" ]; then
  echo -e "${BOLD}${RED}Not a directory: $ARG_DIRECTORY${RESET}" >&2
  exit 1
fi

# The name template ends up in file names, so reject path separators.
if [[ "$ARG_NAME" == */* || -z "$ARG_NAME" ]]; then
  echo -e "${BOLD}${RED}Invalid name template: $ARG_NAME${RESET}" >&2
  exit 1
fi

echo -ne "${BOLD}Directory: ${RESET}"
echo "$ARG_DIRECTORY"
echo -ne "${BOLD}Name     : ${RESET}"
echo "$ARG_NAME"

# ------------------------------------------------------------------------------
# Step 1: Discover the candidate photos (direct children only).
# ------------------------------------------------------------------------------

FD_EXTENSION_ARGS=()
for EXTENSION in "${PHOTO_EXTENSIONS[@]}"; do
  FD_EXTENSION_ARGS+=(--extension "$EXTENSION")
done

# Symlinks are not followed; only regular files are renamed.
readarray -d "" PHOTOS < <(
  fd --max-depth 1 --hidden --no-ignore --print0 --type file \
    "${FD_EXTENSION_ARGS[@]}" . "$ARG_DIRECTORY"
)

# All direct children, needed below to detect target names that are already
# taken by something we do not rename.
readarray -d "" ALL_ENTRIES < <(
  fd --max-depth 1 --hidden --no-ignore --print0 . "$ARG_DIRECTORY"
)

# ------------------------------------------------------------------------------
# Step 2: Deal with leftovers of an interrupted previous run.
# ------------------------------------------------------------------------------
#
# Such a leftover is a photo that was parked under a temporary name and never
# got its final name. Renaming within a directory is atomic, so a leftover is
# always a complete file - never a half-written one. Deleting it would delete a
# photo, which is why "--recover" takes it into this run instead: the new names
# only depend on the EXIF dates, so the leftover simply gets the name it
# deserves, like every other photo.

readarray -d "" LEFTOVERS < <(
  fd --max-depth 1 --hidden --no-ignore --print0 --type file "$TMP_REGEX" "$ARG_DIRECTORY"
)

if [ "${#LEFTOVERS[@]}" -gt 0 ]; then
  echo
  echo -e "${BOLD}${YELLOW}Found ${#LEFTOVERS[@]} leftover(s) of an interrupted run:${RESET}" >&2
  for LEFTOVER in "${LEFTOVERS[@]}"; do
    echo "  ${LEFTOVER##*/}" >&2
  done

  if [ "$ARG_RECOVER" -ne 1 ]; then
    echo >&2
    echo "These are photos that were parked under a temporary name. Nothing was" >&2
    echo "renamed. Re-run with --recover to take them into a new attempt, or move" >&2
    echo "them out of the way manually." >&2
    exit 1
  fi

  # Recovery is only safe if every leftover is still a photo we can place, so
  # the EXIF dates are verified before anything is touched (see step 3).
  echo "Recovering: they take part in this run like every other photo." >&2
  echo >&2
  PHOTOS+=("${LEFTOVERS[@]}")
fi

if [ "${#PHOTOS[@]}" -eq 0 ]; then
  echo "No photos found. Nothing to do."
  exit 0
fi

# The EXIF data is read in a single batch call whose output is line-based.
# File names containing newlines would break that parsing, so they are rejected
# up-front instead of being silently mishandled.
for PHOTO in "${PHOTOS[@]}"; do
  if [[ "$PHOTO" == *$'\n'* ]]; then
    echo -e "${BOLD}${RED}Refusing to work on a file name containing a newline.${RESET}" >&2
    exit 1
  fi
done

# ------------------------------------------------------------------------------
# Step 3: Read the EXIF creation date of each photo (single batch call).
# ------------------------------------------------------------------------------

# Each output line looks like "<date> <path>". The date never contains a space,
# so splitting at the first space is unambiguous, even for file names with
# spaces. Photos without the tag produce no line at all (-if filter) and are
# therefore ignored.
readarray -t EXIF_LINES < <(
  exiftool \
    -quiet -quiet \
    -ignoreMinorErrors \
    -dateFormat '%Y-%m-%d_%H-%M-%S' \
    -if "\$$EXIF_DATE_TAG" \
    -printFormat "\${$EXIF_DATE_TAG} \${Directory}/\${FileName}" \
    "${PHOTOS[@]}" || true
)

if [ "${#EXIF_LINES[@]}" -eq 0 ]; then
  echo "No photos with an EXIF creation date found. Nothing to do."
  exit 0
fi

# A photo without an EXIF date is simply ignored - but ignoring a leftover
# would leave it stranded under its temporary name forever. Rather than that,
# refuse to do anything.
# Names are compared, as they are unique within the directory and independent
# of how the path was spelled.
DATED_NAMES=()
for LINE in "${EXIF_LINES[@]}"; do
  DATED_NAME="${LINE#* }"
  DATED_NAMES+=("${DATED_NAME##*/}")
done

for LEFTOVER in "${LEFTOVERS[@]}"; do
  LEFTOVER_NAME="${LEFTOVER##*/}"
  FOUND=0
  for DATED_NAME in "${DATED_NAMES[@]}"; do
    if [ "$DATED_NAME" = "$LEFTOVER_NAME" ]; then
      FOUND=1
      break
    fi
  done
  if [ "$FOUND" -eq 0 ]; then
    echo -e "${BOLD}${RED}Cannot recover, no EXIF creation date: $LEFTOVER_NAME${RESET}" >&2
    echo "Nothing was renamed. Please rename that file manually." >&2
    exit 1
  fi
done

# Sorted by date first, then by the current path. This makes the numbering
# deterministic, also for photos taken within the same second.
readarray -t SORTED_EXIF_LINES < <(printf '%s\n' "${EXIF_LINES[@]}" | LC_ALL=C sort)

# ------------------------------------------------------------------------------
# Step 4: Plan the renaming.
# ------------------------------------------------------------------------------

PHOTO_COUNT="${#SORTED_EXIF_LINES[@]}"
NUMBER_WIDTH="${#PHOTO_COUNT}"
if [ "$NUMBER_WIDTH" -lt "$MIN_NUMBER_WIDTH" ]; then
  NUMBER_WIDTH="$MIN_NUMBER_WIDTH"
fi

# Parallel arrays: RENAME_SOURCES[i] is renamed to RENAME_TARGETS[i].
RENAME_SOURCES=()
RENAME_TARGETS=()
SKIPPED_COUNT=0

# Names of all photos we are about to rename. Only these may legitimately
# occupy a target name. Names are compared in lower case, as the file system
# may be case-insensitive (typical for USB drives), where "FOO.JPG" and
# "foo.jpg" denote the same file.
declare -A PHOTO_NAMES=()
for LINE in "${SORTED_EXIF_LINES[@]}"; do
  PHOTO_PATH="${LINE#* }"
  PHOTO_NAME="${PHOTO_PATH##*/}"
  PHOTO_NAMES["${PHOTO_NAME,,}"]=1
done

# Names of all other directory entries, i.e., the ones we never touch.
declare -A FOREIGN_NAMES=()
for ENTRY in "${ALL_ENTRIES[@]}"; do
  # "fd" prints directories with a trailing slash, which has to go before the
  # name can be extracted.
  ENTRY="${ENTRY%/}"
  ENTRY_NAME="${ENTRY##*/}"
  ENTRY_NAME="${ENTRY_NAME,,}"
  if [ -z "${PHOTO_NAMES[$ENTRY_NAME]:-}" ]; then
    FOREIGN_NAMES["$ENTRY_NAME"]=1
  fi
done

NUMBER=0
for LINE in "${SORTED_EXIF_LINES[@]}"; do
  PATH_OF_PHOTO="${LINE#* }"
  CURRENT_NAME="${PATH_OF_PHOTO##*/}"
  if [[ "$CURRENT_NAME" =~ $TMP_REGEX ]]; then
    # A recovered leftover: its extension sits in front of the ".tmp" suffix.
    EXTENSION="${CURRENT_NAME%"$TMP_SUFFIX"}"
    EXTENSION="${EXTENSION##*.}"
  else
    EXTENSION="${CURRENT_NAME##*.}"
  fi
  EXTENSION="${EXTENSION,,}"

  NUMBER=$((NUMBER + 1))
  TARGET_NAME=$(printf '%s (%0*d).%s' "$ARG_NAME" "$NUMBER_WIDTH" "$NUMBER" "$EXTENSION")

  # A target name held by a file we do not rename would be overwritten or force
  # us to skew the numbering. Neither is acceptable, so abort instead.
  if [ -n "${FOREIGN_NAMES[${TARGET_NAME,,}]:-}" ]; then
    echo -e "${BOLD}${RED}Target name is occupied by a file that is not renamed: $TARGET_NAME${RESET}" >&2
    echo "Nothing was renamed. Move that file away or choose another name." >&2
    exit 1
  fi

  if [ "$TARGET_NAME" = "$CURRENT_NAME" ]; then
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  RENAME_SOURCES+=("$PATH_OF_PHOTO")
  RENAME_TARGETS+=("$ARG_DIRECTORY/$TARGET_NAME")
done

echo -ne "${BOLD}Photos   : ${RESET}"
echo "$PHOTO_COUNT with an EXIF creation date (of ${#PHOTOS[@]} candidates)"
echo -ne "${BOLD}Renamings: ${RESET}"
echo "${#RENAME_SOURCES[@]} ($SKIPPED_COUNT already have their final name)"

for I in "${!RENAME_SOURCES[@]}"; do
  SOURCE_NAME="${RENAME_SOURCES[$I]##*/}"
  TARGET_NAME="${RENAME_TARGETS[$I]##*/}"
  echo -e "  ${BOLD}$SOURCE_NAME${RESET} -> ${BOLD}$TARGET_NAME${RESET}"
done

if [ "${#RENAME_SOURCES[@]}" -eq 0 ]; then
  echo "Nothing to do."
  exit 0
fi

if [ "$ARG_DRY_RUN" -eq 1 ]; then
  echo "Dry run. Do nothing."
  exit 0
fi

# Renaming is hard to undo, so ask for confirmation. The prompt reads from the
# terminal rather than from stdin, so that the script also behaves when its
# stdin is a pipe. Without a terminal, "--yes" is mandatory.
if [ "$ARG_YES" -ne 1 ]; then
  # Without a controlling terminal, there is nobody to ask: "--yes" is required.
  # The braces ensure that stderr is redirected before the failing redirection.
  if ! { exec 3< /dev/tty; } 2>/dev/null; then
    echo -e "${BOLD}${RED}No terminal for the confirmation prompt. Use --yes.${RESET}" >&2
    exit 1
  fi
  read -r -u 3 -p "Rename these ${#RENAME_SOURCES[@]} photos? [y/N] " ANSWER
  exec 3<&-
  if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "Aborted. Nothing was renamed."
    exit 0
  fi
fi

# ------------------------------------------------------------------------------
# Step 5: Perform the renaming in two phases.
# ------------------------------------------------------------------------------
#
# Phase 1 moves every photo to a unique temporary name, phase 2 moves it from
# there to its final name. This way, a target name is guaranteed to be free
# when it is used, even if it is currently held by another photo of this very
# batch (which also covers swaps and longer renaming cycles).

TMP_PATHS=()

# Reports leftover temporary files, so that a failed run leaves an obvious and
# recoverable state instead of seemingly lost photos.
report_leftovers() {
  local LEFTOVER
  for LEFTOVER in "${TMP_PATHS[@]}"; do
    if [ -e "$LEFTOVER" ]; then
      echo -e "${BOLD}${YELLOW}Leftover temporary file: $LEFTOVER${RESET}" >&2
    fi
  done
}
trap report_leftovers ERR

for I in "${!RENAME_SOURCES[@]}"; do
  # The target extension is preserved in the temporary name, see TMP_PREFIX.
  TMP_EXTENSION="${RENAME_TARGETS[$I]##*.}"
  TMP_PATH="$ARG_DIRECTORY/$TMP_PREFIX$$.$I.$TMP_EXTENSION$TMP_SUFFIX"
  # Should never happen, but a silent overwrite would cost a photo.
  if [ -e "$TMP_PATH" ]; then
    echo -e "${BOLD}${RED}Temporary file already exists: $TMP_PATH${RESET}" >&2
    exit 1
  fi
  mv --no-clobber --no-target-directory "${RENAME_SOURCES[$I]}" "$TMP_PATH"
  TMP_PATHS+=("$TMP_PATH")
done

for I in "${!TMP_PATHS[@]}"; do
  TARGET="${RENAME_TARGETS[$I]}"
  if [ -e "$TARGET" ]; then
    echo -e "${BOLD}${RED}Target unexpectedly exists: $TARGET${RESET}" >&2
    exit 1
  fi
  mv --no-clobber --no-target-directory "${TMP_PATHS[$I]}" "$TARGET"
done

trap - ERR

echo -e "${BOLD}${GREEN}Renamed ${#RENAME_SOURCES[@]} photos.${RESET}"
