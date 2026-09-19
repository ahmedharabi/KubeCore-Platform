#!usr/bin/env bash

set -euo pipefail

source source "$PROJECT_ROOT/scripts/common.sh"

NAME="$1"
IP="$2"
VCPU="$3"
RAM="$4"
DISK="$5"

VM_PATH="$VM_DIR/$NAME"
DISK_PATH="$VM_PATH/$NAME.qcow2"
SEED_PATH="$VM_PATH/$NAME-seed.iso"

USER_DATA_TEMPLATE="$PROJECT_ROOT/vm/cloud-init/user-data.yaml"
NETWORK_TEMPLATE="$PROJECT_ROOT/vm/cloud-init/network-config.yaml"

mkdir -p "$VM_PATH"

if vm_exists "$NAME"; then
    die "VM already exists: $NAME"
fi

if [[ ! -f "$UBUNTU_IMAGE" ]]; then
    die "Ubuntu cloud image not found: $UBUNTU_IMAGE"
fi

if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    die "SSH public key not found: ~/.ssh/id_ed25519.pub"
fi

SSH_PUBLIC_KEY="$(cat "$HOME/.ssh/id_ed25519.pub")"

log "Creating disk for $NAME..."

qemu-img create \
    -f qcow2 \
    -F qcow2 \
    -b "$UBUNTU_IMAGE" \
    "$DISK_PATH" \
    "${DISK}G"

TEMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TEMP_DIR"' EXIT

sed \
    -e "s|__SSH_USER__|$SSH_USER|g" \
    -e "s|__SSH_PUBLIC_KEY__|$SSH_PUBLIC_KEY|g" \
    "$USER_DATA_TEMPLATE" \
    > "$TEMP_DIR/user-data"

sed \
    -e "s|__IP__|$IP|g" \
    -e "s|__GATEWAY__|$NETWORK_GATEWAY|g" \
    "$NETWORK_TEMPLATE" \
    > "$TEMP_DIR/network-config"

cat > "$TEMP_DIR/meta-data" <<EOF
instance-id: $NAME
local-hostname: $NAME
EOF

log "Creating cloud-init seed ISO..."

cloud-localds \
    --network-config="$TEMP_DIR/network-config" \
    "$SEED_PATH" \
    "$TEMP_DIR/user-data" \
    "$TEMP_DIR/meta-data"

log "Creating VM: $NAME"

virt-install \
    --name "$NAME" \
    --memory "$RAM" \
    --vcpus "$VCPU" \
    --cpu host-passthrough \
    --disk "path=$DISK_PATH,format=qcow2,bus=virtio" \
    --disk "path=$SEED_PATH,device=cdrom" \
    --network "network=$NETWORK_NAME,model=virtio" \
    --os-variant ubuntu24.04 \
    --import \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole

log "VM created: $NAME"
