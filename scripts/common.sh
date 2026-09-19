#!/usr/bin/env bash
set -euo pipefail

source "$HOME/Desktop/Projects/kubecore/config.env"

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || \
        die "Required command not found: $1"
}

vm_exists() {
    virsh dominfo "$1" >/dev/null 2>&1
}

vm_running() {
    [[ "$(virsh domstate "$1" 2>/dev/null || true)" == "running" ]]
}
vm_stopped() {
    [[ "$(virsh domstate "$1" 2>/dev/null || true)" == "shut off" ]]
}

wait_for_vm() {
    local vm="$1"

    for _ in {1..30}; do
        if vm_running "$vm"; then
            return 0
        fi

        sleep 2
    done

    die "VM did not start: $vm"
}

wait_for_ssh() {
    local ip="$1"

    log "Waiting for SSH on $ip..."

    for _ in {1..60}; do
        if ssh \
            -o ConnectTimeout=2 \
            -o StrictHostKeyChecking=no \
            -o BatchMode=yes \
            "$SSH_USER@$ip" true 2>/dev/null
        then
            log "SSH available on $ip"
            return 0
        fi

        sleep 3
    done

    die "SSH did not become available on $ip"
}

ssh_node() {
    local ip="$1"
    shift

    ssh \
        -o StrictHostKeyChecking=no \
        "$SSH_USER@$ip" "$@"
}

scp_to_node() {
    local source="$1"
    local ip="$2"
    local destination="$3"

    scp \
        -o StrictHostKeyChecking=no \
        "$source" \
        "$SSH_USER@$ip:$destination"
}