#!/usr/bin/env bash

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

cat >~/pool-default.xml <<EOL
<pool type='dir'>
  <name>default</name>
  <source>
  </source>
  <target>
    <path>/var/lib/libvirt/images</path>
    <permissions>
      <mode>0711</mode>
      <owner>0</owner>
      <group>0</group>
      <label>system_u:object_r:virt_image_t:s0</label>
    </permissions>
  </target>
</pool>
EOL

sudo virsh pool-define ~/pool-default.xml
sudo virsh pool-autostart default
sudo virsh pool-start default

virsh net-destroy default
virsh net-undefine default

if [ "$(hostname -d)" == "prd.lan" ]; then
  stage="prd"
  lan_prefix="172.16.10"
else
  stage="dev"
  lan_prefix="172.16.20"
fi

cat > /root/${stage}-lan.xml <<EOL
<network connections='2'>
  <name>${stage}-lan</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOL

virsh net-define /root/${stage}-lan.xml
virsh net-autostart ${stage}-lan
virsh net-start ${stage}-lan

cat > /etc/sysctl.d/10-ip-forward.conf <<EOL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects=0
EOL

sudo cat /var/lib/puppet/ssl/certs/ca.pem
sudo reboot

