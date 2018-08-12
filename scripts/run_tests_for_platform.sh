#!/bin/sh
#
# Run tests for a test platform.
#

set -eu

cd "$(dirname "$0")"/..
. ./scripts/common.sh

# Configuration
{
    # Inherited variables
    test -n "${ROTD_ARCHIVE:-}" || exit 78
    test -n "${ROTD_BASENAME:-}" || exit 78
    test -n "${ROTD_VERSION:-}" || exit 78
    test -n "${ROTD_OUTPUT_DIR:-}" || exit 78
    test -n "${PLATFORM:-}" || exit 78

    test -r conf && . ./conf
    # shellcheck source=conf.x86_64
    test -r "conf.$PLATFORM" && . "./conf.$PLATFORM"
    setup_config

    readonly platform_output_dir=${ROTD_OUTPUT_DIR}/${PLATFORM}
    readonly platform_output_url=${platform_output_dir#"$OUTPUT/"}
}

# Check if we should continue.
{
    if test -f "${platform_output_dir}/done.txt"; then
        echo "$(date) -- Already tested: $ROTD_BASENAME / $PLATFORM"
        exit
    fi

    if command -v mmc >/dev/null; then
        echo "$(date) -- Please remove mmc from PATH."
        exit 1
    fi
}

# Install the bootstrap compiler.
{
    mkdir -p "${ROTD_OUTPUT_DIR}"
    grep -Fsqx "$PLATFORM" "${ROTD_OUTPUT_DIR}/platforms.txt" ||
        echo "$PLATFORM" >>"${ROTD_OUTPUT_DIR}/platforms.txt"

    mkdir -p "${platform_output_dir}"
    log_file="${platform_output_dir}/install.txt"
    status_file="${platform_output_dir}/status.00.html"
    status_header="<h2><a href='${platform_output_url}'>${PLATFORM}</a></h2>"
    update_status "<p>Installation in progress, started at $(date)" \
        "<a href='$platform_output_url/install.txt'>(log)</a>" \
        "</p>"
    update_index

    rm -rf "$build_dir" "$install_dir"

    set +e
    {
        mkdir -p "$build_dir" &&
            cd "$build_dir" &&
            tar -zxf "$ROTD_ARCHIVE" &&
            cd "$ROTD_BASENAME" &&
            ./configure \
                --prefix="$install_dir" \
                --enable-libgrades="$INSTALL_LIBGRADES" &&
            cp -Rl tests tests.clean &&
            make install PARALLEL="-j${PARALLEL}"
        install_status=$?
    } >"$log_file" 2>&1
    set -e

    {
        echo "$status_header"
        if test "$install_status" -ne 0; then
            echo "<p>make install failed with exit status $install_status"
            echo "<a href='$platform_output_url/install.txt'>(log)</a></p>"
        fi
        echo "<pre>"
        # Should HTML escape this, oh well.
        "${scripts_dir}/filter_warnings_or_errors.awk" <"$log_file" || true
        echo "</pre>"
    } >"$status_file"
    update_index

    export PATH="$install_dir/bin:$PATH"
}

# Function to run bootcheck in a grade.
# Input variables: grade_num, grade
run_bootcheck() {
    mkdir -p "${platform_output_dir}/${grade}"
    log_file="${platform_output_dir}/${grade}/bootcheck.txt"

    status_file=$(printf '%s/status.%02d.html' "$platform_output_dir" "$grade_num")
    status_header="<h3><a href='${platform_output_url}/${grade}'>${grade}</a></h3>"
    update_status "<p>Bootcheck in progress, started at $(date)" \
        "<a href='${platform_output_url}/${grade}/bootcheck.txt'>(log)</a>" \
        "</p>"
    update_index

    case "$grade" in
        *csharp* | *java*)
            bootcheck_args="--use-mmc-make -m EXTRA_MCFLAGS+=-j${PARALLEL}"
            ;;
        *)
            bootcheck_args="-j${PARALLEL}"
            ;;
    esac

    set +e
    (
        ulimit -t 300
        if type pre_bootcheck >/dev/null; then
            GRADE=$grade pre_bootcheck
        fi && {
            grep -H . Mmake.stage.params 2>/dev/null
            if test "$TEST_SUITE" = no; then
                bootcheck_args="$bootcheck_args --no-test-suite"
            fi
            ./tools/bootcheck --grade "$grade" --test-params \
                --delete-deep-data $bootcheck_args
        }
    ) >"$log_file" 2>&1
    bootcheck_status=$?
    set -e

    # 'cp -t' is not portable.
    "${scripts_dir}/list_test_error_files.sh" | while IFS= read -r errfile; do
        cp "$errfile" "${platform_output_dir}/${grade}" || true
    done

    {
        echo "$status_header"
        if test "$bootcheck_status" -ne 0; then
            echo "<p>Bootcheck terminated with exit status $bootcheck_status"
            echo "<a href='${platform_output_url}/${grade}/bootcheck.txt'>(log)</a>"
            echo "</p>"
        fi
        echo "<pre>"
        if "${scripts_dir}/filter_warnings_or_errors.awk" <"$log_file"; then
            if grep -q "^starting the test suite at" "$log_file"; then
                test "$bootcheck_status" -ne 0 || echo "No problems."
            else
                echo "Skipped test suite."
            fi
        fi
        echo "</pre>"
    } >"$status_file"
    update_index
}

# Bootcheck in each grade.
{
    if test "$install_status" -eq 0; then
        grade_num=1
        for grade in $TEST_GRADES; do
            if test "$grade_num" -ne 1; then
                rm -rf tests
                cp -Rl tests.clean tests
            fi
            run_bootcheck
            grade_num=$((grade_num + 1))
        done
    fi
}

# Mark this ROTD and test platform done.
{
    date >"${platform_output_dir}/done.txt"
}
