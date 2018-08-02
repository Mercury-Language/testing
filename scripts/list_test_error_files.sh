#!/bin/sh
#
# Print list of files to save from the tests directory.
#

set -eu

find tests -type f -name '*.log' |
    while IFS= read -r log; do
        echo "$log"
        logdir=$(dirname "$log")
        awk -v prefix="$logdir/" \
            '/mmc / && match($0, /[^ /]*[.]err/) {
                print prefix substr($0, RSTART, RLENGTH)
            }' <"$log"
    done
