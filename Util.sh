#!/bin/bash
# ------------------------------------------------------------------------------
# Created by Ulysses Carlos on 03/29/2026 at 02:32 PM
#
# Util.sh
#
# ------------------------------------------------------------------------------
function echo_wait() {
    echo "$1"
    sleep 1

}

function print_dashed_line() {
    for ((i = 1; i <= DASH_LINE_LENGTH; i++));
    do
        printf "-"
    done
    echo ""
}

function create_required_directories() {
    mkdir -p "$TEMP_DOWNLOAD_PATH"
}

function cd_or_exit() {
    cd "$1" || (echo "Error: Could not change directory to $1. Aborting." && exit 1)
}

