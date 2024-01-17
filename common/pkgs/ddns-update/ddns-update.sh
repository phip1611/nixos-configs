#!/usr/bin/env bash

# @describe
# DDNS update script for `all-inkl.com` and similar DDNS services that updates
# DDNS information via a HTTP request to the URL performing the request using
# HTTP basic authentication.
#
# @option --config!            Path to JSON configuration.

set -euo pipefail

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

ARG_CFG="${argc_config}"

# check if is file or link to file
if  [ -f "$ARG_CFG" ] || { [ -h "$ARG_CFG" ] && [ -f "$(readlink -e "$ARG_CFG")" ]; }; then
    DDNS_SCHEME=$(cat "$ARG_CFG" | jq -r '.scheme')
    DDNS_HOST=$(cat "$ARG_CFG" | jq -r '.host')
    DDNS_USER=$(cat "$ARG_CFG" | jq -r '.username')
    DDNS_PASS=$(cat "$ARG_CFG" | jq -r '.password')
    DDNS_EXPECT_MSG=$(cat "$ARG_CFG" | jq -r '."expect-message"')
    echo -e "$(ansi bold)Host: $(ansi reset)$DDNS_HOST"
    echo -e "$(ansi bold)User: $(ansi reset)$DDNS_USER"
    echo -e "$(ansi bold)Pass: $(ansi reset)***"
    echo "Invoking: $DDNS_SCHEME://$DDNS_HOST with user=$DDNS_USER and password=***.:"
    OUTPUT=$(curl -s -u "$DDNS_USER:$DDNS_PASS" --basic "$DDNS_SCHEME://$DDNS_HOST")
    echo "Response:"
    echo $OUTPUT
    if [[ "$DDNS_EXPECT_MSG" != "" && "$DDNS_EXPECT_MSG" != "null" ]]; then
        echo -e "$(ansi bold)Checking for expected message \"$DDNS_EXPECT_MSG\" in output:$(ansi reset)"
        echo $OUTPUT | grep -q "$DDNS_EXPECT_MSG" || (echo -e "$(ansi bold)$(ansi red)Not found. The update might have failed!$(ansi reset)" && exit 1)
        echo -e "$(ansi bold)$(ansi green)Yes$(ansi reset) ✅"
    else
        echo -e "$(ansi bold)$(ansi yellow)Ignoring result. \"expected-message\" not configured. Treating as success.$(ansi reset)"
    fi

else
    echo -e "$(ansi red)$(ansi bold)Please make sure to pass a path to a valid JSON configuration file.$(ansi reset)"
    exit 1
fi
