#!/usr/bin/env bash
set -euo pipefail

NODE="${1:-}"
if [[ "$NODE" == "cp1" ]]; then
  echo "SSH into control plane 1"
  IP="192.168.50.10"
elif [[ "$NODE" == "wk1" ]]; then
  echo "SSH into worker node 1"
  IP="192.168.50.11"
elif [[ "$NODE" == "wk2" ]]; then
  echo "SSH into worker node 2"
  IP="192.168.50.12"
else
  echo "ERROR: invalid node"
fi
ssh "${SSH_USER}@${IP}"

