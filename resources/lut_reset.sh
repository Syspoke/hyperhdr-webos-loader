#!/bin/bash


LOCKFILE="/tmp/lut_script.lock"


HYPERHDR_PATH="/media/developer/apps/usr/palm/services/org.webosbrew.hyperhdr.loader.service/hyperhdr"
ROOT_HYPERHDR_PATH="/home/root/.hyperhdr"
TMP_DIR="/tmp"



clean_up() {
    
    rm -f "$HYPERHDR_PATH"/*.3d
    rm -f "$HYPERHDR_PATH"/*.zst
    rm -f "$ROOT_HYPERHDR_PATH"/*.3d
    rm -f "$ROOT_HYPERHDR_PATH"/*.zst
    rm -f "$TMP_DIR/lut*.tar.gz"

}


send_notification() {
    luna-send -a webosbrew -f -n 1 luna://com.webos.notification/createToast '{"sourceId":"webosbrew","message": "<b>Reset LUT successful!</b>"}'
}

if [[ -f "$LOCKFILE" ]]; then
    exit 1
fi

touch "$LOCKFILE"

trap 'rm -f "$LOCKFILE"; exit' EXIT

clean_up
send_notification

rm -f "$LOCKFILE"
