#!/usr/bin/env bash
set -euo pipefail
source "$PROJECT_ROOT/scripts/common.sh"

IP="192.168.50.10"
wait_for_ssh "$IP"
scp $SSH_USER@$IP:/etc/rancher/rke2/rke2.yaml ~/.kube/kubecore.yaml
log "Kubeconfig saved to: ~/.kube/kubecore.yaml"