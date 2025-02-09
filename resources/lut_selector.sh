#!/bin/bash

LOCKFILE="/tmp/lut_script.lock"
HYPERHDR_PATH="/media/developer/apps/usr/palm/services/org.webosbrew.hyperhdr.loader.service/hyperhdr"
TMP_DIR="/tmp"
REQUIRED_SPACE_MB=460

LUT_URL_COMPRESSED="https://github.com/satgit62/satgit62.github.io/releases/download/v0.2.0-alpha/lut_compressed.tar.gz"
LUT_URL_UNCOMPRESSED="https://github.com/satgit62/satgit62.github.io/releases/download/v0.2.0-alpha/lut_uncompressed.tar.gz"


check_space() {
    local available_space=$(df "$HYPERHDR_PATH" | awk 'NR==2 {print $4}')
    available_space=$((available_space / 1024))

    if (( available_space < REQUIRED_SPACE_MB )); then
        luna-send -a webosbrew -f -n 1 luna://com.webos.notification/createToast '{"sourceId":"webosbrew","message": "<b>No enough space available to install uncompressed LUT!!!</b>"}'
        exit 1
    fi
}


clean_up() {
    rm -f "$HYPERHDR_PATH"/*.3d
    rm -f "$HYPERHDR_PATH"/*.zst
    rm -f "$ROOT_HYPERHDR_PATH"/*.3d
    rm -f "$ROOT_HYPERHDR_PATH"/*.zst
    rm -f "$TMP_DIR/lut*.tar.gz"
}


download_and_decompress() {
    local lut_url="$1"
    local lut_file="$TMP_DIR/lut_temp.tar.gz"
    curl -L -o "$lut_file" "$lut_url" || {
        exit 1
    }

    tar xvzf "$lut_file" -C "$HYPERHDR_PATH" || {
        rm -f "$lut_file"
        exit 1
    }

    rm -f "$lut_file"
}


send_notification() {
    local lut_type="$1"
    luna-send -a webosbrew -f -n 1 luna://com.webos.notification/createToast "{\"sourceId\":\"webosbrew\",\"message\": \"<b>${lut_type^} Lut installed!</b>\"}"
}


if [[ -f "$LOCKFILE" ]]; then
    exit 1
fi

touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"; exit' EXIT


if [[ $# -eq 0 ]]; then
    echo "Usage: $0 {compressed|uncompressed|reset}"
    exit 1
fi

LUT_TYPE="$1"

if [[ "$LUT_TYPE" == "reset" ]]; then
    clean_up
    echo "Clean up completed."
    rm -f "$LOCKFILE"
    exit 0
fi


if [[ "$LUT_TYPE" == "compressed" ]]; then
    LUT_URL="$LUT_URL_COMPRESSED"
elif [[ "$LUT_TYPE" == "uncompressed" ]]; then
    LUT_URL="$LUT_URL_UNCOMPRESSED"
else
    echo "Invalid LUT type specified. Use 'compressed', 'uncompressed', or 'reset'."
    exit 1
fi

clean_up

if [[ "$LUT_TYPE" == "uncompressed" ]]; then
    check_space
fi

download_and_decompress "$LUT_URL"

send_notification "$LUT_TYPE"

rm -f "$LOCKFILE"