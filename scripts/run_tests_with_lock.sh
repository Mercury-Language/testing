#!/bin/sh
#
# Run all tests while holding the lock.
#

set -eu

cd "$(dirname "$0")"/..
. ./scripts/common.sh

# Configuration
{
    test -r conf && . ./conf
    setup_config
}

# Check if download page has been updated.
{
    curl -s -I "$DL_URL" | grep '^Last-Modified: ' >"$lastmod.tmp$$"
    if cmp -s "$lastmod" "$lastmod.tmp$$"; then
        rm "$lastmod.tmp$$"
        echo "$(date) -- Download page unmodified since last run."
        exit
    else
        mv "$lastmod.tmp$$" "$lastmod"
    fi
}

# Scrape latest ROTD.
{
    href=$(
        curl -s "$DL_URL" |
            awk '/Latest ROTD:/ { k=1 }
                 /<a href=.*\.tar\.xz/ && k==1 { print; k=2 }'
    )
    href=${href#*\"}
    href=${href%\"*}
    case $href in
        */mercury-srcdist-rotd-????-??-??.tar.xz) ;;
        *)
            echo "$(date) -- Unexpected URL: $href"
            exit 1
            ;;
    esac

    readonly rotd_url=${DL_URL}/${href}
    readonly rotd_filename=${href#*/}
    export ROTD_ARCHIVE=${archives_dir}/${rotd_filename}
    export ROTD_BASENAME=${rotd_filename%.tar.xz}
    export ROTD_VERSION=${ROTD_BASENAME#*mercury-srcdist-rotd-}
    export ROTD_OUTPUT_DIR=${OUTPUT}/builds/rotd-${ROTD_VERSION}
}

# Download archive.
(
    mkdir -p "${ROTD_OUTPUT_DIR}"
    status_file="${ROTD_OUTPUT_DIR}/status.html"
    status_header="<h1>${ROTD_BASENAME}</h1>"
    update_status "<p>Downloading</p>"
    update_index

    cd "$archives_dir"
    if test -f "$rotd_filename" || curl "$rotd_url" -o "$rotd_filename"; then
        update_status ""
        update_index
    else
        update_status "<p>Failed to download $rotd_url</p>"
        update_index
        exit 1
    fi
)

# Test each platform.
{
    export PLATFORM
    for PLATFORM in $PLATFORMS; do
        "${scripts_dir}/run_tests_for_platform.sh"
    done
}
