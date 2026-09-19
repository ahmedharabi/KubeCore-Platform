#!/usr/bin/env bash

set -euo pipefail

swapoff -a

sed -i '/ swap / s/^/#/' /etc/fstab

apt-get update

apt-get install -y \
    curl \
    ca-certificates \
    apparmor-parser \
    chrony \
    open-iscsi

systemctl enable --now chrony

cat > /etc/modules-load.d/rke2.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/99-rke2.conf <<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

sysctl --system

echo "RKE2 node preparation complete."