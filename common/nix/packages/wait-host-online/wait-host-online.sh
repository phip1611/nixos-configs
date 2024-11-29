#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# Waits until a host becomes available by checking if it replies to ping
# messages. The difference to `ping -W` is that this doesn't send a single
# network request with a long wait time, but that it sends many requests. This
# is especially helpful when one waits for a host to come online again, such as
# when starting a VM or live-migrating a VM to another host.
#
# @arg host!
# @option --timeout=60 Timeout in seconds
# @option --request-delay=0.05 Delay between requests in seconds. Increase for rate limiting. Must not be less than the minimal amount of time needed for a roundtrip.

set -euo pipefail

# argc CLI magic
eval "$(argc --argc-eval "$0" "$@")" # Must appear after all "@cmd" directives!

ping_cancelled=false
# seconds since UNIX epoch
timestamp_begin=$(date +%s)
DIFF=0

echo "Waiting for host to become available ..."
until ping -c 1 -W $argc_request_delay "$argc_host" >/dev/null 2>&1; do
  DIFF=$(($(date +%s) - $timestamp_begin))
  if [ $DIFF -ge $argc_timeout ]; then
    echo "Timeout!"
    exit 1
  fi
done &    # The "&" backgrounds it
trap "kill $!; ping_cancelled=true" SIGINT
wait $!          # Wait for the loop to exit, one way or another
trap - SIGINT    # Remove the trap, now we're done with it
echo "Host is available (took ${DIFF}s)"
