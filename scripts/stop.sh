#!/usr/bin/env bash

set -euo pipefail

export PROJECT_ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
source "$PROJECT_ROOT/scripts/common.sh"
source "$PROJECT_ROOT/config.env"

for VM in \
    "$WORKER2_NAME" \
    "$WORKER1_NAME" \
    "$CP_NAME"
do

    if ! vm_exists "$VM"; then
        warn "$VM does not exist."
        continue
    fi

    if vm_stopped "$VM"; then
        log "$VM already stopped."
        continue
    fi

    log "Shutting down $VM..."

    virsh shutdown "$VM"
done

for VM in \
    "$WORKER2_NAME" \
    "$WORKER1_NAME" \
    "$CP_NAME"
do

    log "Waiting for $VM to stop..."

    for _ in {1..30}; do

        if vm_stopped "$VM"; then
            break
        fi

        sleep 2
    done

done

log "Cluster stopped."