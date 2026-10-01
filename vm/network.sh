#! /usr/bin/env bash

set -oue pipefail

PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$PROJECT_ROOT/scripts/common.sh"
source "$PROJECT_ROOT/config.env"

if virsh net-info "$NETWORK_NAME" >/dev/null 2>&1; then
    log "Network already exists: $NETWORK_NAME"
    exit 0
fi

cat > /tmp/rke2-lab-network.xml <<EOF
<network>
  <name>${NETWORK_NAME}</name>

  <forward mode='nat'/>

  <bridge
    name='virbr20'
    stp='on'
    delay='0'/>

  <ip
    address='${NETWORK_GATEWAY}'
    netmask='255.255.255.0'>
  </ip>
</network>
EOF

virsh net-define /tmp/rke2-network.xml
virsh net-autostart "$NETWORK_NAME"
virsh net-start "$NETWORK_NAME"

rm /tmp/rke2-network.xml