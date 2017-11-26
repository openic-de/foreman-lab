#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

if ps aux | grep "/usr/share/foreman" | grep -v grep 2> /dev/null
then
  log-progress-nl "Foreman appears to all already be installed. Exiting..."
else
  log-progress-nl "setting up /etc/hosts"

  hostname="$(hostname -s)"
  lanname="$(hostname -d)"

  if [ ${lanname} == "prd.lan" ]; then
    hostip="172.16.10.10"
    hostip_tmp="$(ip addr show eth1|grep "inet\ " | awk '{print $2}'|cut -d'/' -f1)"
  else
    hostip="172.16.20.10"
    hostip_tmp="$(ip addr show eth1|grep "inet\ " | awk '{print $2}'|cut -d'/' -f1)"
  fi

  sudo cat >/etc/hosts <<EOL
${hostip} ${hostname}.${lanname}     ${hostname}
127.0.0.1    localhost localhost.localdomain localhost4 localhost4.localdomain4
::1          localhost localhost.localdomain localhost6 localhost6.localdomain6
EOL

  log-execute "sudo yum -y install gpg yum-utils wget memcached" "installing gpg yum-utils wget memcached"
  log-execute "sudo yum-config-manager --enable rhel-7-server-optional-rpms rhel-server-rhscl-7-rpms" "enabling red hat optional repository"

  log-execute "sudo yum -y install foreman-installer" "installing foreman-installer"

  log-execute "sudo systemctl enable memcached" "memcached: enabling service"
  log-execute "sudo systemctl start memcached" "memcached: starting service"

  log-execute "sudo firewall-cmd --permanent --add-port=53/tcp" "firewalld: add-port dns server"
  log-execute "sudo firewall-cmd --permanent --add-port=53/udp" "firewalld: add-port dns server"
  log-execute "sudo firewall-cmd --permanent --add-port=67-68/udp" "firewalld: add-port dhcp server"
  log-execute "sudo firewall-cmd --permanent --add-port=69/udp" "firewalld: add-port tftp server"
  log-execute "sudo firewall-cmd --permanent --add-port=80/tcp" "firewalld: add-port http server"
  log-execute "sudo firewall-cmd --permanent --add-port=443/tcp" "firewalld: add-port https server"
  log-execute "sudo firewall-cmd --permanent --add-port=5910-5930/tcp" "firewalld: add-port vnc server consoles"
  log-execute "sudo firewall-cmd --permanent --add-port=8140/tcp" "firewalld: add-port  puppet master server"
  sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="'${hostip}'" port protocol="tcp" port="8443" accept' # "firewalld: adding port smart proxy for access from foreman"
  log-execute "sudo firewall-cmd --reload" "firewalld: reloading"

  log-execute-show-output "sudo foreman-installer --enable-foreman --enable-foreman-proxy --enable-puppet --enable-foreman-cli --enable-foreman-plugin-ansible --enable-foreman-plugin-bootdisk --enable-foreman-plugin-memcache --enable-foreman-plugin-monitoring --enable-foreman-plugin-tasks --enable-foreman-plugin-setup --enable-foreman-plugin-templates --enable-foreman-compute-libvirt" "executing foreman-installer"

  log-execute "sudo systemctl enable httpd" "httpd: enabling service"
  log-execute "sudo systemctl start httpd" "httpd: starting service"
  log-execute "sudo systemctl enable foreman-proxy" "foreman-proxy: enabling service"
  log-execute "sudo systemctl start foreman-proxy" "foreman-proxy: starting service"
fi

log-progress-nl "done"
