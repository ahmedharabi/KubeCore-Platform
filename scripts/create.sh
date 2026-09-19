#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_command virsh
require_command virt-install
require_command qemu-img
require_command cloud-localds
require_command ssh
require_command scp

log "Creating libvirt network..."

"$PROJECT_ROOT/vm/network.sh"

log "Creating control plane..."

"$PROJECT_ROOT/vm/create-vm.sh" \
    "$CP_NAME" \
    "$CP_IP" \
    "$CP_VCPU" \
    "$CP_RAM" \
    "$CP_DISK"

log "Creating worker 1..."

"$PROJECT_ROOT/vm/create-vm.sh" \
    "$WORKER1_NAME" \
    "$WORKER1_IP" \
    "$WORKER_VCPU" \
    "$WORKER_RAM" \
    "$WORKER_DISK"

log "Creating worker 2..."

"$PROJECT_ROOT/vm/create-vm.sh" \
    "$WORKER2_NAME" \
    "$WORKER2_IP" \
    "$WORKER_VCPU" \
    "$WORKER_RAM" \
    "$WORKER_DISK"

wait_for_ssh "$CP_IP"
wait_for_ssh "$WORKER1_IP"
wait_for_ssh "$WORKER2_IP"

log "Preparing control plane..."

scp_to_node \
    "$PROJECT_ROOT/rke2/prepare-node.sh" \
    "$CP_IP" \
    "/tmp/prepare-node.sh"

ssh_node "$CP_IP" \
    "sudo bash /tmp/prepare-node.sh"

log "Installing RKE2 server..."

scp_to_node \
    "$PROJECT_ROOT/rke2/install-server.sh" \
    "$CP_IP" \
    "/tmp/install-server.sh"

ssh_node "$CP_IP" \
    "sudo bash /tmp/install-server.sh '$CP_IP' '$CP_NAME'"

log "Retrieving RKE2 token..."

TOKEN="$(
    ssh_node "$CP_IP" \
    "sudo cat /var/lib/rancher/rke2/server/node-token"
)"

if [[ -z "$TOKEN" ]]; then
    die "Failed to retrieve RKE2 token"
fi

log "Preparing worker 1..."

scp_to_node \
    "$PROJECT_ROOT/rke2/prepare-node.sh" \
    "$WORKER1_IP" \
    "/tmp/prepare-node.sh"

ssh_node "$WORKER1_IP" \
    "sudo bash /tmp/prepare-node.sh"

log "Installing worker 1..."

scp_to_node \
    "$PROJECT_ROOT/rke2/install-agent.sh" \
    "$WORKER1_IP" \
    "/tmp/install-agent.sh"

ssh_node "$WORKER1_IP" \
    "sudo bash /tmp/install-agent.sh '$CP_IP' '$TOKEN' '$WORKER1_NAME'"

log "Preparing worker 2..."

scp_to_node \
    "$PROJECT_ROOT/rke2/prepare-node.sh" \
    "$WORKER2_IP" \
    "/tmp/prepare-node.sh"

ssh_node "$WORKER2_IP" \
    "sudo bash /tmp/prepare-node.sh"

log "Installing worker 2..."

scp_to_node \
    "$PROJECT_ROOT/rke2/install-agent.sh" \
    "$WORKER2_IP" \
    "/tmp/install-agent.sh"

ssh_node "$WORKER2_IP" \
    "sudo bash /tmp/install-agent.sh '$CP_IP' '$TOKEN' '$WORKER2_NAME'"

log "Waiting for all Kubernetes nodes..."

for _ in {1..60}; do

    if ssh_node "$CP_IP" \
        "sudo /var/lib/rancher/rke2/bin/kubectl \
        --kubeconfig /etc/rancher/rke2/rke2.yaml \
        get nodes --no-headers 2>/dev/null" \
        | grep -q "$WORKER2_NAME"
    then
        break
    fi

    sleep 5
done

log "Cluster nodes:"

ssh_node "$CP_IP" \
    "sudo /var/lib/rancher/rke2/bin/kubectl \
    --kubeconfig /etc/rancher/rke2/rke2.yaml \
    get nodes -o wide"

log "Cluster creation complete."

