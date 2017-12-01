#!/usr/bin/env bash

source /tmp/common.sh

log-execute "sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm" "installing epel-release-latest"

log-execute "sudo yum -y update" "updating operating system software"
log-execute "sudo yum -y upgrade" "upgrading operating system software"

log-execute "sudo yum -y install git createrepo firewalld rsync nginx" "installing git createrepo firewalld rsync nginx"

log-execute "mkdir -p /var/www/html/repos/centos/7/{os/x86_64,updates/x86_64,extras/x86_64,centosplus/x86_64}" "setting up centos repository directories"
log-execute "mkdir -p /var/www/html/repos/epel/7/x86_64" "setting up epel repository directories"
log-execute "mkdir -p /var/www/html/repos/puppetlabs/el/7/{products/x86_64,dependencies/x86_64,devel/x86_64,PC1/x86_64}" "setting up puppetlabs repository directories"
log-execute "mkdir -p /var/www/html/repos/theforeman/{releases/1.15/el7/x86_64,plugins/1.15/el7/x86_64}" "setting up foreman repository directories"

log-execute "createrepo /var/www/html/repos/centos/7/os/x86_64/" "createrepo centos os"
log-execute "createrepo /var/www/html/repos/centos/7/updates/x86_64/" "createrepo centos updates"
log-execute "createrepo /var/www/html/repos/centos/7/extras/x86_64/" "createrepo centos extras"
log-execute "createrepo /var/www/html/repos/centos/7/centosplus/x86_64/" "createrepo centos centosplus"
log-execute "createrepo /var/www/html/repos/epel/7/x86_64/" "createrepo epel"
log-execute "createrepo /var/www/html/repos/puppetlabs/el/7/products/x86_64" "createrepo puppetlabs products"
log-execute "createrepo /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64" "createrepo puppetlabs dependencies"
log-execute "createrepo /var/www/html/repos/puppetlabs/el/7/devel/x86_64" "createrepo puppetlabs devel"
log-execute "createrepo /var/www/html/repos/puppetlabs/el/7/PC1/x86_64" "createrepo puppetlabs PC1"
log-execute "createrepo /var/www/html/repos/theforeman/releases/1.15/el7/x86_64" "createrepo puppetlabs foreman releases"
log-execute "createrepo /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64" "createrepo puppetlabs foreman plugins"

log-execute "mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig" "backup nginx configuration"

log-progress-nl "setting up nginx configuration"
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

log-progress-nl "setting up nginx repository configuration"
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

log-progress-nl "setting up sync mirror script"
cat >~/sync-mirror.sh <<EOL
#!/bin/bash

#---------
reposync --gpgcheck -l --repoid=base --download_path=/var/www/html/repos/centos/7 --downloadcomps --download-metadata &
reposync --gpgcheck -l --repoid=centosplus --download_path=/var/www/html/repos/centos/7 --downloadcomps --download-metadata &
reposync --gpgcheck -l --repoid=extras --download_path=/var/www/html/repos/centos/7 --downloadcomps --download-metadata &
reposync --gpgcheck -l --repoid=updates --download_path=/var/www/html/repos/centos/7 --downloadcomps --download-metadata &
#---------
reposync            -l --repoid=epel --download_path=/var/www/html/repos/centos/7 --downloadcomps --download-metadata &
#---------

#---------
rsync -avz --delete --exclude='repodata' rsync://mirror.netcologne.de/centos/7/os/x86_64/ /var/www/html/repos/centos/7/base/ &
#rsync -avz --delete --exclude='repodata' rsync://mirror.netcologne.de/centos/7/updates/x86_64/ /var/www/html/repos/centos/7/updates/ &
#rsync -avz --delete --exclude='repodata' rsync://mirror.netcologne.de/centos/7/extras/x86_64/ /var/www/html/repos/centos/7/extras/ &
#rsync -avz --delete --exclude='repodata' rsync://mirror.netcologne.de/centos/7/centosplus/x86_64/ /var/www/html/repos/centos/7/centosplus/ &
#---------
#rsync -avz --delete --exclude='repodata' --exclude='debug' rsync://mirror.netcologne.de/fedora-epel/7/x86_64/ /var/www/html/repos/centos/7/epel/ &
#---------

rsync -avz --delete --exclude='repodata' rsync://rsync.puppet.com/packages/yum/el/7/products/x86_64/ /var/www/html/repos/puppetlabs/el/7/products/x86_64/ &
rsync -avz --delete --exclude='repodata' rsync://rsync.puppet.com/packages/yum/el/7/dependencies/x86_64/ /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64/ &
rsync -avz --delete --exclude='repodata' rsync://rsync.puppet.com/packages/yum/el/7/devel/x86_64/ /var/www/html/repos/puppetlabs/el/7/devel/x86_64/ &
rsync -avz --delete --exclude='repodata' rsync://rsync.puppet.com/packages/yum/el/7/PC1/x86_64/ /var/www/html/repos/puppetlabs/el/7/PC1/x86_64/ &
#---------
rsync -avz --delete --exclude='repodata' rsync://rsync.theforeman.org/yum/releases/1.15/el7/x86_64/ /var/www/html/repos/theforeman/releases/1.15/el7/x86_64/ &
rsync -avz --delete --exclude='repodata' rsync://rsync.theforeman.org/yum/plugins/1.15/el7/x86_64/ /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64/ &

wait

createrepo /var/www/html/repos/centos/7/base -g /var/www/html/repos/centos/7/base/comps.xml
createrepo /var/www/html/repos/centos/7/base/x86_64/ -g comps.xml &
createrepo /var/www/html/repos/centos/7/updates/x86_64/ -g comps.xml &
createrepo /var/www/html/repos/centos/7/extras/x86_64/ -g comps.xml &
createrepo /var/www/html/repos/centos/7/centosplus/x86_64/ -g comps.xml &
#---------
createrepo /var/www/html/repos/centos/7/epel/x86_64/ -g comps.xml &
#---------
createrepo /var/www/html/repos/puppetlabs/el/7/products/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/dependencies/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/devel/x86_64/ &
createrepo /var/www/html/repos/puppetlabs/el/7/PC1/x86_64/ &
#---------
createrepo /var/www/html/repos/theforeman/releases/1.15/el7/x86_64/ &
createrepo /var/www/html/repos/theforeman/plugins/1.15/el7/x86_64/ &

chown -R nginx:noboy /var/www/html/repos
EOL

log-execute "chmod +x ~/sync-mirror.sh" "ensure sync-mirror.sh is executable"

log-progress-nl "setting up root cron job"
cat >/var/spool/cron/root <<EOL
15 1 * * * /root/sync-mirror.sh
EOL

log-execute "sudo systemctl enable firewalld" "firewalld: enabling"
log-execute "sudo systemctl start firewalld" "firewalld: starting"
log-execute "sudo firewall-cmd --permanent --add-service=http" "firewalld: allowing http service"

log-execute "sudo firewall-cmd --reload" "firewalld: reloading"

log-execute "sudo systemctl enable nginx.service" "nginx: enabling"
log-execute "sudo systemctl start nginx.service" "nginx: starting"
