#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

log-progress-nl "setting up default pool configuration"
cat >/root/pool-default.xml <<EOL
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

log-execute "sudo virsh pool-define /root/pool-default.xml" "setting up default pool"
log-execute "sudo virsh pool-autostart default" "setting default pool to autostart"
log-execute "sudo virsh pool-start default" "starting default pool"

log-execute "virsh net-destroy default" "destroy default network"
log-execute "virsh net-undefine default" "undefining default network"

if [ "$(hostname -d)" == "prd.lan" ]; then
  stage="prd"
  lan_prefix="172.16.10"
else
  stage="dev"
  lan_prefix="172.16.20"
fi

log-progress-nl "setting up ${stage}-lan network configuration"
cat > /root/${stage}-lan.xml <<EOL
<network connections='2'>
  <name>${stage}-lan</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOL

log-execute "virsh net-define /root/${stage}-lan.xml" "defining ${stage}-lan network"
log-execute "virsh net-autostart ${stage}-lan" "setting ${stage}-lan network to autostart"
log-execute "virsh net-start ${stage}-lan" "starting ${stage}-lan network"

log-progress-nl "setting up ip forwarding"
cat > /etc/sysctl.d/10-ip-forward.conf <<EOL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects=0
EOL
log-progress-nl "done"
