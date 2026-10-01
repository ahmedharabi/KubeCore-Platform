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

mkdir -p /tmp/rke2-artifacts
cd /tmp/rke2-artifacts

BASE="https://github.com/rancher/rke2/releases/download/v1.36.4%2Brke2r1"

fetch() {
    try=0
    until curl -4 --http1.1 -C - --retry 5 --retry-all-errors \
               --connect-timeout 20 -fL -o "$2" "$1"
    do
        rc=$?
        [ "$rc" = 22 ] && { echo "[ERROR] $2 not found (404)" >&2; return 1; }
        try=$((try + 1))
        [ "$try" -ge 20 ] && { echo "[ERROR] gave up on $2" >&2; return 1; }
        echo "[WARN] reset on $2, resuming (attempt $try)..."
        sleep 5
    done
}

fetch "${BASE}/sha256sum-amd64.txt"             sha256sum-amd64.txt
fetch "${BASE}/rke2.linux-amd64.tar.gz"         rke2.linux-amd64.tar.gz
fetch "${BASE}/rke2-images.linux-amd64.tar.zst" rke2-images.linux-amd64.tar.zst

grep -E 'rke2\.linux-amd64\.tar\.gz|rke2-images\.linux-amd64\.tar\.zst' \
    sha256sum-amd64.txt | sha256sum -c -

mkdir -p /var/lib/rancher/rke2/agent/images
cp rke2-images.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/

curl -4 -sfL https://get.rke2.io -o install.sh

INSTALL_RKE2_ARTIFACT_PATH=/tmp/rke2-artifacts sh install.sh

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