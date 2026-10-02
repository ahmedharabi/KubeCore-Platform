#!/usr/bin/env bash
set -euo pipefail

echo "Checking host requirements..."
echo

missing=0

check_command() {
    local name="$1"

    if command -v "$name" >/dev/null 2>&1; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name"
        missing=1
    fi
}

check_service() {
    local name="$1"

    if systemctl is-active --quiet "$name"; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name"
        missing=1
    fi
}

check_file() {
    local path="$1"

    if [[ -e "$path" ]]; then
        echo "  ✓ $path"
    else
        echo "  ✗ $path"
        missing=1
    fi
}

echo "Commands:"
check_command virsh
check_command virt-install
check_command qemu-img
check_command qemu-system-x86_64
check_command cloud-localds
check_command ssh
check_command scp
check_command curl
check_command git

echo
echo "Services:"
check_service libvirtd

echo
echo "Hardware:"
check_file /dev/kvm

echo

if [[ "$missing" -eq 0 ]]; then
    echo "All host requirements are satisfied."
else
    echo "Some host requirements are missing."
    exit 1
fi