#!/usr/bin/env bash

# Exits with 0 if there is a default network route and its connection is not
# metered, and with 1 otherwise. Intended for `ExecCondition=` in systemd
# services that download a lot: systemd then skips the run instead of
# marking the service as failed.
#
# Without a running NetworkManager, the connection counts as not metered.

set -euo pipefail

log() {
  printf '%s\n' "$*" >&2
}

# Find the name of the default network interface: the one that the kernel
# picks for an IPv4 address on the internet, or else for an IPv6 one. This
# also covers multipath routes, which have no "dev" in their first line of
# `ip route list default`. No packets are sent. awk reads all lines, as
# closing the pipe early would kill `ip` with SIGPIPE.
dev=$({
  ip route get 1.1.1.1 2>/dev/null ||
    ip -6 route get 2001:db8::1 2>/dev/null ||
    true
} | awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1) }')

if [[ -z "$dev" ]]; then
  log "No default network route found."
  exit 1
fi

if [[ "$(nmcli -t -g RUNNING general 2>/dev/null)" != "running" ]]; then
  # This is the case on servers with static configuration and no network
  # manager. There, I typically have an unmetered LAN connection. Further,
  # without NetworkManager, there is no way to query that information.
  log "NetworkManager is not running; assuming connection is not metered."
  exit 0
fi

# An unknown state counts as metered.
metered=$(nmcli -t -g GENERAL.METERED device show "$dev" 2>/dev/null || true)

case "$metered" in
"no" | "no (guessed)")
  log "Default connection on '$dev' is not metered."
  exit 0
  ;;
*)
  log "Default connection on '$dev' is metered."
  exit 1
  ;;
esac
