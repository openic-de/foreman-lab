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

cat >/etc/sysctl.d/bridge.conf <<EOL
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-arptables=0
EOL

cat >/etc/udev/rules.d/99-bridge.rules <<EOL
ACTION=="add", SUBSYSTEM=="module", KERNEL=="bridge", RUN+="/sbin/sysctl -p /etc/sysctl.d/bridge.conf"
EOL

grep -v "NM_CONTROLLED" /etc/sysconfig/network-scripts/ifcfg-eth1 >/etc/sysconfig/network-scripts/ifcfg-eth1-new
echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-eth1-new
echo "BRIDGE=br0" >> /etc/sysconfig/network-scripts/ifcfg-eth1-new
mv /etc/sysconfig/network-scripts/ifcfg-eth1-new /etc/sysconfig/network-scripts/ifcfg-eth1

hostname="$(hostname -s)"
lanname="$(hostname -d)"

if [ ${lanname} == "prd.lan" ]; then
  hostip="172.16.10.10"
else
  hostip="172.16.20.10"
fi

cat >/etc/sysconfig/network-scripts/ifcfg-br0 <<EOL
# If unsure what NETMASK, GATEWAY or IPV6_DEFAULTGW should be, check the
# original copy of ifcfg-eth0 or ask your hosting provider.

DEVICE=br0
NAME=br0
# Change to 'no' to disable NetworkManager for this interface.
NM_CONTROLLED=yes
ONBOOT=yes
TYPE=Bridge
# If you want to turn on Spanning Tree Protocol, ask your hosting
# provider first as it may conflict with their network.
STP=off
# If STP is off, set to 0. If STP is on, set to 2 (or greater).
DELAY=0

IPADDR=${hostip}
NETMASK=255.255.255.0
GATEWAY=${hostip}
DNS1=${hostip}
PEERDNS=yes
EOL

sudo systemctl restart network
sudo systemctl restart NetworkManager
sudo systemctl restart dnsmasq

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
