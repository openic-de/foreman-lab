#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

# kvm + libvirt
sudo chown -R foreman:foreman /usr/share/foreman
#sudo -u foreman ssh foreman@kvm.adm.lan "echo kvm public key distribution successful."
#sudo -u foreman virsh -c qemu+ssh://foreman@kvm.adm.lan/system list

# tftp
sudo mkdir -p /var/lib/tftpboot/{boot,pxelinux.cfg}
sudo yum -y install syslinux
sudo find /var/lib/tftpboot/ -type d | xargs chmod g+s
sudo cp /usr/share/syslinux/{pxelinux.0,menu.c32,chain.c32} /var/lib/tftpboot
sudo chgrp -R nobody /var/lib/tftpboot

log-progress-nl "done"
