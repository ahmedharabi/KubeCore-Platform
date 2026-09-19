#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="$1"
NODE_NAME="$2"

mkdir -p /etc/rancher/rke2

cat > /etc/rancher/rke2/config.yaml <<EOF
write-kubeconfig-mode: "0644"

node-name: ${NODE_NAME}

tls-san:
  - ${SERVER_IP}
EOF

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-server.service
systemctl start rke2-server.service

echo "Waiting for RKE2 server..."

for _ in {1..60}; do

    if systemctl is-active --quiet rke2-server; then
        if /var/lib/rancher/rke2/bin/kubectl \
            --kubeconfig /etc/rancher/rke2/rke2.yaml \
            get nodes >/dev/null 2>&1
        then
            echo "RKE2 server is ready."
            exit 0
        fi
    fi

    sleep 5
done

journalctl -u rke2-server --no-pager -n 100

exit 1