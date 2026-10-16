#!/usr/bin/env bash
set -euo pipefail

timeout_limit="${DOPAMINE_TEST_TIMEOUT:-120s}"

for arg in "$@"; do
    if [[ "$arg" == "--stay-open" ]]; then
        exec "$@"
    fi
done

if [[ "$timeout_limit" == "0" || "$timeout_limit" == "off" ]]; then
    exec "$@"
fi

exec timeout --signal=TERM --kill-after=5s "$timeout_limit" "$@"
