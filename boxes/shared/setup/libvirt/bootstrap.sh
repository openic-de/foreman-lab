#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

log-execute "yum install -y qemu-kvm qemu-img libvirt libvirt-client virt-install dejavu-lgc-sans-fonts virt-manager virt-top virt-viewer" "installing libvirt and tools"
log-execute "systemctl enable libvirtd" "libvirtd: enabling service"
log-execute "systemctl start libvirtd" "libvirtd: starting service"

log-progress-nl "done"
