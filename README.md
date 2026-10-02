# KubeCore

A production-style Kubernetes platform built on RKE2, Rancher's hardened, security-focused Kubernetes distribution. The cluster runs on KVM virtual machines provisioned with cloud-init, and everything inside it will be managed through GitOps with Argo CD.

The whole platform is scripted in Bash, so it can be rebuilt from scratch with a single command.

![Architecture](docs/architecture.png)

## What's in it

It runs on a single Linux host. `kcluster create` sets up:

- a libvirt NAT network, `rke2-lab` on `192.168.50.0/24`
- three Ubuntu 24.04 VMs with static IPs, set up by cloud-init:
  - `cp1` at `192.168.50.10`, the RKE2 server
  - `worker1` at `192.168.50.11`, an RKE2 agent
  - `worker2` at `192.168.50.12`, an RKE2 agent
- RKE2 on all three nodes, with the workers joined to `cp1`

By default the control plane gets 2 vCPUs, 4 GB of RAM and a 15 GB disk, and each worker gets 2 vCPUs, 2 GB of RAM and a 10 GB disk. You can change this in `config.env`.



## Requirements

Linux with KVM enabled and about 6 GB of free RAM.

## Setup

**1. Clone into `/`.** libvirt can't read files under your home directory.

```bash
sudo git clone https://github.com/ahmedharabi/KubeCore-Platform.git /KubeCore-Platform
sudo chown -R "$USER":"$USER" /KubeCore-Platform
```

**2. Add `kcluster` to your PATH.** Use `~/.zshrc` if you're on zsh.

```bash
echo 'export PATH="/KubeCore-Platform:$PATH"' >> ~/.bashrc
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.bashrc
source ~/.bashrc
```

**3. Install the packages.**

Fedora:

```bash
sudo dnf install -y \
    @virtualization \
    cloud-utils \
    openssh-clients \
    curl \
    git
sudo systemctl enable --now libvirtd
```

Debian / Ubuntu:

```bash
sudo apt update
sudo apt install -y \
    qemu-system-x86 \
    libvirt-daemon-system \
    libvirt-clients \
    virtinst \
    cloud-image-utils \
    openssh-client \
    curl \
    git
sudo systemctl enable --now libvirtd
```

**4. Join the `libvirt` and `kvm` groups**, then log out and back in.

```bash
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"
```

**5. Download the Ubuntu cloud image.**

```bash
mkdir -p /KubeCore-Platform/vm/images
cd /KubeCore-Platform/vm/images
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

**6. Create an SSH key** if `~/.ssh/id_ed25519.pub` doesn't exist.

```bash
ssh-keygen -t ed25519
```

**7. Check the host.** Everything should show ✓.

```bash
kcluster check
```

## Usage

Set `SSH_USER` in `config.env`, then:

```bash
kcluster create   # network, VMs and RKE2
kcluster stop     # shut down the workers, then the control plane
kcluster start    # boot everything again
```

### kubectl from the host

```bash
scp $SSH_USER@192.168.50.10:/etc/rancher/rke2/rke2.yaml ~/.kube/kubecore.yaml
sed -i 's/127.0.0.1/192.168.50.10/' ~/.kube/kubecore.yaml
export KUBECONFIG=~/.kube/kubecore.yaml
kubectl get nodes
```

## Layout

```text
kcluster          CLI wrapper, "kcluster <command>" runs scripts/<command>.sh
config.env        cluster settings, loaded by every script
scripts/          check / create / start / stop, plus common.sh helpers
vm/               network and VM creation, cloud-init templates
rke2/             node prep and RKE2 server/agent install, run on the VMs over SSH
gitops/           Argo CD manifests (empty for now)
docs/             architecture diagram
```

## Status

- [x] VM provisioning and networking
- [x] cloud-init
- [ ] RKE2 cluster (scripts written, still being tested)
- [ ] Cilium
- [ ] Argo CD
- [ ] Longhorn, PostgreSQL
- [ ] Prometheus, Grafana, Loki
- [ ] Internal apps
