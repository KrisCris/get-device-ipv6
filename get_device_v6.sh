#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="$SCRIPT_DIR/get_device_v6.data"
MAC=$1

if [ -z "$MAC" ]; then
    echo "Error: MAC address not provided."
    echo "Usage: $0 <MAC_ADDRESS>"
    exit 1
fi

get_new_ip() {
    NEW_IP="$(echo "$filtered" | head -n 1 | awk '{print $1}')"
    echo "$NEW_IP" > "$LOG_FILE"
    echo "$NEW_IP"
}

try_get_old_ip() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    OLD_IP=$(cat "$LOG_FILE" | head -n 1)
    if [ -z "$OLD_IP" ]; then
        return 1
    fi

    TRY_GET_OLD_IP="$(echo "$filtered" | grep "$OLD_IP" | head -n 1 | awk '{print $1}')"
    if [ "$OLD_IP" == "$TRY_GET_OLD_IP" ]; then
        echo "$OLD_IP"
        exit 0
    fi
    return 1
}

get_ips() {
    RETRIES=0
    MAX_RETRIES=20
    DELAY=10

    while [[ $RETRIES -lt $MAX_RETRIES ]]; do
        filtered=$(ip neigh | grep "$MAC" | grep REACHABLE | grep -vE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|^(fe80:|fc[0-9a-f]{2}:)')

        if [[ -n "$filtered" ]]; then
            break
        fi

        sleep $DELAY
        ((RETRIES++))
    done

    if [[ -z "$filtered" ]]; then
        echo "Failed to get a non-empty result after $MAX_RETRIES attempts."
        exit 1
    fi

    echo "$filtered"
}

filtered="$(get_ips)"
if ! try_get_old_ip; then
    get_new_ip
fi