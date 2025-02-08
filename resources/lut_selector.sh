#!/bin/bash

LOCKFILE="/tmp/lut_script.lock"
HYPERHDR_PATH="/media/developer/apps/usr/palm/services/org.webosbrew.hyperhdr.loader.service/hyperhdr"
ROOT_HYPERHDR_PATH="/home/root/.hyperhdr"
TMP_DIR="/tmp"
REQUIRED_SPACE_MB=460


LUT_URL_COMPRESSED="https://github.com/satgit62/satgit62.github.io/releases/download/v0.2.0-alpha/lut_compressed.tar.gz"
LUT_URL_UNCOMPRESSED="https://github.com/satgit62/satgit62.github.io/releases/download/v0.2.0-alpha/lut_uncompressed.tar.gz"
LUT_URL_DEFAULT="https://github.com/satgit62/satgit62.github.io/releases/download/v0.2.0-alpha/lut_default.tar.gz"


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


create_symlinks() {
    ln -sf "$HYPERHDR_PATH/lut_lin_tables.3d" "$ROOT_HYPERHDR_PATH/lut_lin_tables_sdr.3d"
    ln -sf "$HYPERHDR_PATH/lut_lin_tables_hdr.3d" "$ROOT_HYPERHDR_PATH/lut_lin_tables_hdr.3d"
    ln -sf "$HYPERHDR_PATH/lut_lin_tables_dv.3d" "$ROOT_HYPERHDR_PATH/lut_lin_tables_dv.3d"
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


if [[ $# -ne 1 ]]; then
    echo "Usage: $0 {compressed|uncompressed|default}"
    exit 1
fi

LUT_TYPE="$1"

if [[ "$LUT_TYPE" == "compressed" ]]; then
    LUT_URL="$LUT_URL_COMPRESSED"
elif [[ "$LUT_TYPE" == "uncompressed" ]]; then
    LUT_URL="$LUT_URL_UNCOMPRESSED"
elif [[ "$LUT_TYPE" == "default" ]]; then
    LUT_URL="$LUT_URL_DEFAULT"
else
    echo "Invalid LUT type specified. Use 'compressed', 'uncompressed', or 'default'."
    exit 1
fi

clean_up

if [[ "$LUT_TYPE" == "uncompressed" ]]; then
    check_space
fi

download_and_decompress "$LUT_URL"

if [[ "$LUT_TYPE" == "uncompressed" ]]; then
    create_symlinks
fi

send_notification "$LUT_TYPE"

rm -f "$LOCKFILE"