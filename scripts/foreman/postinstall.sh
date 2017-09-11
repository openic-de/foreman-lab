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

sudo cat /var/lib/puppet/ssl/certs/ca.pem
