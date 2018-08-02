#!/bin/sh
#
# Test latest ROTD. This script can be run as a cron job.
#

set -eu
cd "$(dirname "$0")"
{
    if flock -n 9; then
        echo "$(date) -- Here we go!"
        nice ./scripts/run_tests_with_lock.sh
        echo "$(date) -- Done."
    else
        # Don't clutter up cron logs.
        if test -t 1; then
            echo "$(date) -- Already running."
        fi
    fi
} 9>run/lock
