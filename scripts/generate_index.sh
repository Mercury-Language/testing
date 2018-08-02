#!/bin/sh
#
# Generates index.html
#

set -eu

cd "${1:-output}"

echo '<title>Testing</title>'
echo '<link rel="stylesheet" type="text/css" href="style.css">'

find builds -mindepth 1 -maxdepth 1 -type d -name 'rotd-*' | sort -r |
    while IFS= read -r rotd_dir; do
        echo '<div class="version">'
        cat "${rotd_dir}/status.html" 2>/dev/null || true
        cat "${rotd_dir}/platforms.txt" 2>/dev/null |
            while IFS= read -r platform; do
                echo '<div class="platform">'
                cat "${rotd_dir}/${platform}"/status.*.html 2>/dev/null || true
                echo '</div>'
            done
        echo '</div>'
    done
