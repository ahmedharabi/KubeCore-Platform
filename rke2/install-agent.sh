#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="$1"
TOKEN="$2"
NODE_NAME="$3"

mkdir -p /etc/rancher/rke2

cat > /etc/rancher/rke2/config.yaml <<EOF
server: https://${SERVER_IP}:9345

token: ${TOKEN}

node-name: ${NODE_NAME}
EOF

curl -sfL https://get.rke2.io | \
    INSTALL_RKE2_TYPE="agent" sh -

systemctl enable rke2-agent.service
systemctl start rke2-agent.service

echo "Waiting for RKE2 agent..."

for _ in {1..60}; do

    if systemctl is-active --quiet rke2-agent; then
        echo "RKE2 agent is running."
        exit 0
    fi

    sleep 5
done

journalctl -u rke2-agent --no-pager -n 100

exit 1