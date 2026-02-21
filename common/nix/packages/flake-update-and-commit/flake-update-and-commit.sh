#!/usr/bin/env bash
set -euo pipefail

# Ensure we're in a git repository
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: not inside a git repository"
    exit 1
}

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "flake: bump all dependencies" > "$tmpfile"
echo "" >> "$tmpfile"

# Iterate over all flake inputs
inputs=$(jq -r '.nodes.root.inputs | keys[]' flake.lock)

for input in $inputs; do
    # Get old lastModified / version
    old_val=$(jq -r ".nodes.\"$input\".locked.lastModified // .nodes.\"$input\".locked.version // \"<unknown>\"" flake.lock)

    if [[ "$old_val" =~ ^[0-9]+$ ]]; then
        old_date=$(date -d @"$old_val" "+%Y-%m-%d")
    elif [[ "$old_val" != "<unknown>" ]]; then
        old_date=$(date -d "$old_val" "+%Y-%m-%d")
    else
        old_date="<unknown>"
    fi

    echo "Trying to update input: $input"
    nix flake update "$input"

    # Get new lastModified / version
    new_val=$(jq -r ".nodes.\"$input\".locked.lastModified // .nodes.\"$input\".locked.version // \"<unknown>\"" flake.lock)
    if [[ "$new_val" =~ ^[0-9]+$ ]]; then
        new_date=$(date -d @"$new_val" "+%Y-%m-%d")
    elif [[ "$new_val" != "<unknown>" ]]; then
        new_date=$(date -d "$new_val" "+%Y-%m-%d")
    else
        new_date="<unknown>"
    fi

    # Only include inputs that actually changed
    if [[ "$old_date" != "$new_date" ]]; then
        echo "$input: $old_date -> $new_date" >> "$tmpfile"
    fi
done

# Stage flake.lock changes
git add flake.lock

# Only commit if there are changes
if [[ $(wc -l < "$tmpfile") -gt 2 ]]; then
    echo "" >> "$tmpfile"
    echo "This commit was generated via:" >> "$tmpfile"
    echo "nix run github:phip1611/nixos-configs#flake-update-and-commit" >> "$tmpfile"
    git commit -F "$tmpfile"
    echo "Done: flake inputs bumped and committed."
else
    echo "No inputs changed - nothing to commit."
fi
