#!/usr/bin/env bash

sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum -y update && yum -y upgrade

sudo yum -y install git createrepo epel-release firewalld rsync nginx

mkdir -p /var/www/html/repos/centos/7/{os/x86_64,updates/x86_64,extras/x86_64,centosplus/x86_64}   # Base and Update Repos
mkdir -p /var/www/html/repos/epel/7/x86_64   # EPEL Repo
mkdir -p /var/www/html/repos/puppetlabs/el/7/{products/x86_64,dependencies/x86_64,devel/x86_64,PC1/x86_64}
mkdir -p /var/www/html/repos/theforeman/{releases/1.15/el7/x86_64,plugins/1.15/el7/x86_64}

createrepo /var/www/html/repos/centos/7/os/x86_64/   # Initialize CentOS Base Repo
createrepo /var/www/html/repos/centos/7/updates/x86_64/   # Initialize CentOS Update Repo
createrepo /var/www/html/repos/centos/7/extras/x86_64/   # Initialize CentOS Update Repo
createrepo /var/www/html/repos/centos/7/centosplus/x86_64/   # Initialize CentOS Update Repo
createrepo /var/www/html/repos/epel/7/x86_64/   # Initialize EPEL 7 Repo
createrepo /var/www/html/repos/puppetlabs/el/7/products/x86_64
createrepo /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64
createrepo /var/www/html/repos/puppetlabs/el/7/devel/x86_64
createrepo /var/www/html/repos/puppetlabs/el/7/PC1/x86_64
createrepo /var/www/html/repos/theforeman/releases/1.15/el7/x86_64
createrepo /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cat >/etc/nginx/nginx.conf <<EOL
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;

  sendfile            on;
  tcp_nopush          on;
  tcp_nodelay         on;
  keepalive_timeout   65;
  types_hash_max_size 2048;

  include             /etc/nginx/mime.types;
  default_type        application/octet-stream;

  include /etc/nginx/conf.d/*.conf;
}
EOL

cat >/etc/nginx/conf.d/repo.conf <<EOL
server {
  listen  80;
  server_name  localhost;
  root  /var/www/html/repos;

  location  / {
    autoindex  on;
  }
}
EOL

cat >~/sync-mirror.sh <<EOL
#!/bin/bash

rsync -avz --exclude='repo*' rsync://mirror.netcologne.de/centos/7/os/x86_64/ /var/www/html/repos/centos/7/os/x86_64/ &
rsync -avz --exclude='repo*' rsync://mirror.netcologne.de/centos/7/updates/x86_64/ /var/www/html/repos/centos/7/updates/x86_64/ &
rsync -avz --exclude='repo*' rsync://mirror.netcologne.de/centos/7/extras/x86_64/ /var/www/html/repos/centos/7/extras/x86_64/ &
rsync -avz --exclude='repo*' rsync://mirror.netcologne.de/centos/7/centosplus/x86_64/ /var/www/html/repos/centos/7/centosplus/x86_64/ &
#---------
rsync -avz --exclude='repo*' --exclude='debug' rsync://mirror.netcologne.de/fedora-epel/7/x86_64/ /var/www/html/repos/epel/7/x86_64/ &
#---------
rsync -avz --exclude='repo*' rsync://rsync.puppet.com/packages/yum/el/7/products/x86_64/ /var/www/html/repos/puppetlabs/el/7/products/x86_64/ &
rsync -avz --exclude='repo*' rsync://rsync.puppet.com/packages/yum/el/7/dependencies/x86_64/ /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64/ &
rsync -avz --exclude='repo*' rsync://rsync.puppet.com/packages/yum/el/7/devel/x86_64/ /var/www/html/repos/puppetlabs/el/7/devel/x86_64/ &
rsync -avz --exclude='repo*' rsync://rsync.puppet.com/packages/yum/el/7/PC1/x86_64/ /var/www/html/repos/puppetlabs/el/7/PC1/x86_64/ &
#---------
rsync -avz --exclude='repo*' rsync://rsync.theforeman.org/yum/releases/1.15/el7/x86_64/ /var/www/html/repos/theforeman/releases/1.15/el7/x86_64/ &
rsync -avz --exclude='repo*' rsync://rsync.theforeman.org/yum/plugins/1.15/el7/x86_64/ /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64/ &

wait

createrepo /var/www/html/repos/centos/7/os/x86_64/ &
createrepo /var/www/html/repos/centos/7/updates/x86_64/ &
createrepo /var/www/html/repos/centos/7/extras/x86_64/ &
createrepo /var/www/html/repos/centos/7/centosplus/x86_64/ &
#---------
createrepo /var/www/html/repos/epel/7/x86_64/ &
#---------
createrepo /var/www/html/repos/puppetlabs/el/7/products/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/devel/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/PC1/x86_64/ &
#---------
createrepo /var/www/html/repos/theforeman/releases/1.15/el7/x86_64/ &
createrepo /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64/ &

wait

EOL
chmod +x ~/sync-mirror.sh

cat >/var/spool/cron/root <<EOL
15 1 * * * /root/sync-mirror.sh
EOL

sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http

sudo firewall-cmd --reload

systemctl enable nginx.service # Enable services
systemctl start nginx.service # Start services
