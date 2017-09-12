#!/usr/bin/env bash

if ps aux | grep "/usr/share/foreman" | grep -v grep 2> /dev/null
then
  echo "Foreman appears to all already be installed. Exiting..."
else
  #sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  #sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
  #sudo rpm -ivh http://yum.theforeman.org/releases/1.14/el7/x86_64/foreman-release.rpm

  #sudo yum -y install epel-release puppetlabs-release foreman-release
  sudo yum -y update && sudo yum -y upgrade

  sudo yum -y install git ansible foreman-installer libvirt-client # memcached

#  sudo system enable memcached
#  sudo system start memcached

  # sudo foreman-installer --enable-foreman --enable-foreman-cli --enable-foreman-proxy --enable-puppet --enable-foreman-plugin-memcache --enable-foreman-plugin-setup --enable-foreman-plugin-tasks --enable-foreman-plugin-templates --enable-foreman-compute-libvirt
  sudo foreman-installer --enable-foreman --enable-foreman-cli --enable-foreman-compute-libvirt --enable-foreman-plugin-ansible --enable-foreman-plugin-bootdisk --enable-foreman-plugin-remote-execution --enable-foreman-plugin-tasks --enable-foreman-proxy --enable-puppet --enable-foreman-plugin-setup

  sudo systemctl enable firewalld
  sudo systemctl start firewalld
  sudo firewall-cmd --permanent --add-interface=virbr0 --zone=trusted
  sudo firewall-cmd --permanent --add-interface=eth0 --zone=public
  sudo firewall-cmd --permanent --zone=public --add-masquerade
  sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -m physdev --physdev-is-bridged -j ACCEPT

  sudo firewall-cmd --reload

  sudo firewall-cmd --permanent --add-port=53/tcp # dns server
  sudo firewall-cmd --permanent --add-port=53/udp # dns server
  sudo firewall-cmd --permanent --add-port=67-69/udp # dhcp + tftp server
  sudo firewall-cmd --permanent --add-port=69/tcp # tftp server
  sudo firewall-cmd --permanent --add-service=http # Foreman Web UI
  sudo firewall-cmd --permanent --add-service=https # Foreman Web UI
  sudo firewall-cmd --permanent --add-port=80/tcp # Foreman Web UI
  sudo firewall-cmd --permanent --add-port=443/tcp # Foreman Web UI
  sudo firewall-cmd --permanent --add-port=5910-5930/tcp # VNC Consoles
  sudo firewall-cmd --permanent --add-port=8140/tcp # Puppet Master
  sudo firewall-cmd --permanent --add-port=8443/tcp # Smart Proxy, open only to foreman

  sudo firewall-cmd --reload

  sudo puppet agent --test --waitforcert=60
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-ntp
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-git
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-vcsrepo
  sudo puppet module install -i /etc/puppet/environments/production/modules jfryman-nginx
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-haproxy
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-apache
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-java
  sudo puppet module install -i /etc/puppet/environments/production/modules deric/zookeeper
  sudo puppet module install -i /etc/puppet/environments/production/modules puppet/kafka
  sudo puppet module install -i /etc/puppet/environments/production/modules elastic/elasticsearch
  sudo puppet module install -i /etc/puppet/environments/production/modules elastic/logstash

  sudo yum -y install qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer dejavu-lgc-sans-fonts xauth

  sudo systemctl enable libvirtd
  sudo systemctl start libvirtd
  sudo usermod -a -G libvirt foreman
  sudo usermod -a -G qemu foreman
  sudo usermod -a -G libvirt vagrant
  sudo usermod -a -G qemu vagrant
  touch ~/.Xauthority
fi