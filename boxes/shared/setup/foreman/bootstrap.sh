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
    hostip="192.168.10.10"
  else
    hostip="192.168.20.10"
  fi

  sudo cat >/etc/hosts <<EOL
${hostip} ${hostname}.${lanname}     ${hostname}
127.0.0.1    localhost localhost.localdomain localhost4 localhost4.localdomain4
::1          localhost localhost.localdomain localhost6 localhost6.localdomain6
EOL

  log-execute "sudo yum -y install gpg yum-utils wget memcached" "installing gpg yum-utils wget memcached"
  log-execute "sudo yum-config-manager --enable rhel-7-server-optional-rpms rhel-server-rhscl-7-rpms" "enabling red hat optional repository"

  log-execute "sudo yum clean all" "cleaning package mangement caches"
  log-execute "sudo yum -y update" "updating system"
  log-execute "sudo yum -y upgrade" "upgrading system"
  log-execute "sudo timedatectl set-timezone Europe/Berlin" "setting timezone to Europe/Berlin"
  log-execute "sudo yum -y install ntp" "installing ntp"
  log-execute "sudo ntpdate de.pool.ntp.org" "setting ntp server de.pool.ntp.org"
  sudo cat >/etc/ntp.conf <<EOL
server 0.de.pool.ntp.org
server 1.de.pool.ntp.org
server 2.de.pool.ntp.org
server 3.de.pool.ntp.org
EOL
  log-execute "sudo systemctl restart ntpd" "restarting ntpd service"
  log-execute "sudo systemctl enable ntpd" "enabling ntpd service on boot"
  log-execute "sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm" "installing puppet labs collection repository"
  log-execute "sudo yum -y install puppetserver" "installing puppetserver"
  log-execute "sudo systemctl start puppetserver" "starting puppetserver"
  log-execute "sudo systemctl enable puppetserver" "enabling puppetserver"
  log-execute "sudo yum -y install puppet-agent" "installing puppet-agent"
  log-execute "sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true" "starting puppet agent"
  log-execute "sudo yum -y install foreman-installer" "installing foreman-installer"

  log-execute "sudo systemctl enable memcached" "memcached: enabling service"
  log-execute "sudo systemctl start memcached" "memcached: starting service"

  log-execute "sudo firewall-cmd --permanent --add-port=53/tcp" "firewalld: add-port dns server"
  log-execute "sudo firewall-cmd --permanent --add-port=53/udp" "firewalld: add-port dns server"
  log-execute "sudo firewall-cmd --permanent --add-port=67-68/udp" "firewalld: add-port dhcp server"
  log-execute "sudo firewall-cmd --permanent --add-port=69/udp" "firewalld: add-port tftp server"
  log-execute "sudo firewall-cmd --permanent --add-port=80/tcp" "firewalld: add-port http server"
  log-execute "sudo firewall-cmd --permanent --add-port=443/tcp" "firewalld: add-port https server"
  log-execute "sudo firewall-cmd --permanent --add-port=3000/tcp" "firewalld: add-port webbricket service"
  log-execute "sudo firewall-cmd --permanent --add-port=5900-5930/tcp" "firewalld: add-port vnc server consoles"
  log-execute "sudo firewall-cmd --permanent --add-port=8140/tcp" "firewalld: add-port  puppet master server"
  log-execute "sudo firewall-cmd --permanent --add-port=8443/tcp" "firewalld: add-port  smart proxy"
  log-execute "sudo firewall-cmd --reload" "firewalld: reloading"

  log-execute-show-output "sudo foreman-installer --enable-foreman --enable-foreman-proxy --enable-puppet --enable-foreman-cli --enable-foreman-plugin-ansible --enable-foreman-plugin-bootdisk --enable-foreman-plugin-memcache --enable-foreman-plugin-monitoring --enable-foreman-plugin-tasks --enable-foreman-plugin-setup --enable-foreman-plugin-templates --enable-foreman-compute-libvirt" "executing foreman-installer"

  log-execute "sudo systemctl enable dnsmasq" "dnsmasq: enabling service"
  log-execute "sudo systemctl start dnsmasq" "dnsmasq: starting service"
  log-execute "sudo systemctl enable tftp" "tftp: enabling service"
  log-execute "sudo systemctl start tftp" "tftp: starting service"
  log-execute "sudo systemctl enable httpd" "httpd: enabling service"
  log-execute "sudo systemctl start httpd" "httpd: starting service"
  log-execute "sudo systemctl enable foreman-proxy" "foreman-proxy: enabling service"
  log-execute "sudo systemctl start foreman-proxy" "foreman-proxy: starting service"
  log-execute "sudo systemctl enable foreman-tasks" "foreman-tasks: enabling service"
  log-execute "sudo systemctl start foreman-tasks" "foreman-tasks: starting service"
fi

log-progress-nl "done"
