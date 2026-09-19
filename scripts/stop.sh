#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

for VM in \
    "$CP_NAME" \
    "$WORKER1_NAME" \
    "$WORKER2_NAME"
do

    if ! vm_exists "$VM"; then
        die "VM does not exist: $VM"
    fi

    if ! vm_running "$VM"; then
        log "Starting $VM..."
        virsh start "$VM"
    else
        log "$VM already running."
    fi
done

wait_for_ssh "$CP_IP"
wait_for_ssh "$WORKER1_IP"
wait_for_ssh "$WORKER2_IP"

log "Cluster started."

"$PROJECT_ROOT/scripts/status.sh"