#!/usr/bin/env bash
set -euo pipefail

log_stderr() {
  local level="$1"
  shift
  printf '[%s]: %s\n' "$level" "$*" >&2
}

log_msg() {
  printf '%s\n' "$*"
}

log_err() {
  log_stderr ERROR "$@"
}

log_info() {
  log_stderr INFO "$@"
}

last_modified_date() {
  local input="$1"
  local last_modified

  # root.inputs maps input names to node names, which may differ (e.g.
  # "nixpkgs_2" when a dependency also has an input called "nixpkgs").
  last_modified=$(jq --arg input "$input" -r '.nodes[.nodes.root.inputs[$input]].locked.lastModified // empty' flake.lock)
  # Some inputs, such as relative path: inputs, have no lastModified.
  if [[ -z "$last_modified" ]]; then
    echo unknown
    return
  fi
  if [[ ! "$last_modified" =~ ^[0-9]+$ ]]; then
    log_err "Missing or invalid lastModified field for flake input '$input'."
    return 1
  fi

  date -d @"$last_modified" --iso-8601=s
}

# Prints the locked revision, or the NAR hash for inputs without one.
locked_rev() {
  local input="$1"

  jq --arg input "$input" -r '.nodes[.nodes.root.inputs[$input]].locked | .rev // .narHash' flake.lock
}

# Inputs that only follow another input have no node of their own.
is_follows_input() {
  local input="$1"

  jq --arg input "$input" -e '.nodes.root.inputs[$input] | type == "array"' flake.lock >/dev/null
}

log_info "Checking repository state before updating flake.lock."

# Ensure we're in a git repository
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  log_err "Not inside a git repository."
  exit 1
}
log_info "Git repository detected."

# Refuse to run when there are already staged changes, because git commit
# would include them together with the flake.lock update.
git diff --cached --quiet || {
  log_err "Git index contains staged changes."
  exit 1
}
log_info "Git index has no pre-existing staged changes."

# Refuse to run when flake.lock already has local modifications, because
# git add flake.lock would stage and commit them together with the update.
git diff --quiet -- flake.lock || {
  log_err "flake.lock has unstaged changes."
  exit 1
}
log_info "flake.lock has no pre-existing unstaged changes."

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "flake: bump all dependencies" >"$tmpfile"
echo "" >>"$tmpfile"

# Iterate over all flake inputs
inputs=$(jq -r '.nodes.root.inputs | keys[]' flake.lock)
input_count=$(jq -r '.nodes.root.inputs | keys | length' flake.lock)
changed_inputs=0

log_info "Found $input_count flake input(s) to update."

for input in $inputs; do
  if is_follows_input "$input"; then
    log_info "Skipping flake input '$input', as it follows another input."
    continue
  fi

  old_date=$(last_modified_date "$input") || exit 1
  old_rev=$(locked_rev "$input")

  log_info "Updating flake input '$input' (current: $old_date)."
  nix flake update "$input"

  new_date=$(last_modified_date "$input") || exit 1
  new_rev=$(locked_rev "$input")

  # Only include inputs that actually changed
  if [[ "$old_date" != "$new_date" ]]; then
    log_info "Flake input '$input' changed: $old_date -> $new_date."
    echo "$input: $old_date -> $new_date" >>"$tmpfile"
    changed_inputs=$((changed_inputs + 1))
  elif [[ "$old_date" == unknown && "$old_rev" != "$new_rev" ]]; then
    log_info "Flake input '$input' changed: $old_rev -> $new_rev."
    echo "$input: rev changed ($new_date)" >>"$tmpfile"
    changed_inputs=$((changed_inputs + 1))
  else
    log_info "Flake input '$input' unchanged ($old_date)."
  fi
done
log_info "Finished updating flake inputs; $changed_inputs of $input_count input(s) changed."

# Stage flake.lock changes
log_info "Staging flake.lock."
git add flake.lock

# Only commit if there are changes
if [[ $(wc -l <"$tmpfile") -gt 2 ]]; then
  log_info "Creating commit for $changed_inputs changed flake input(s)."
  echo "" >>"$tmpfile"
  echo "This commit was generated via:" >>"$tmpfile"
  echo "nix run github:phip1611/nixos-configs#flake-update-and-commit" >>"$tmpfile"
  git commit -F "$tmpfile"
  log_msg "Done: flake inputs bumped and committed."
else
  log_msg "No inputs changed; nothing to commit."
fi
