#!/bin/sh
#
# Shared functions
#

setup_config() {
    DL_URL=${DL_URL:-http://dl.mercurylang.org}
    PLATFORMS=${PLATFORMS:-}
    INSTALL_LIBGRADES=${INSTALL_LIBGRADES:-}
    TEST_GRADES=${TEST_GRADES:-}
    TEST_SUITE=${TEST_SUITE:-yes}
    OUTPUT=${OUTPUT:-output}
    OUTPUT=$(readlink -e "$OUTPUT") # must be absolute path
    PARALLEL=${PARALLEL:-$(nproc 2>/dev/null)}
    PARALLEL=${PARALLEL:-1}
    CROSS_MINGW_HOST=${CROSS_MINGW_HOST:-}
    CROSS_MINGW_LIBGRADES=${CROSS_MINGW_LIBGRADES:-}

    readonly scripts_dir=${PWD}/scripts
    readonly archives_dir=${PWD}/archives
    readonly run_dir=${PWD}/run
    readonly build_dir=${run_dir}/build
    readonly install_dir=${run_dir}/install
    readonly lastmod=${run_dir}/lastmod
    readonly index_html=${OUTPUT}/index.html
}

# Regenerate index.html
update_index() {
    "${scripts_dir}/generate_index.sh" "${OUTPUT}" >"${index_html}.tmp$$"
    mv "${index_html}.tmp$$" "${index_html}"
}

# Write the current status file.
status_header=
status_file=
update_status() {
    printf '%s\n' "$status_header" "$@" >"$status_file"
}
