#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

log-execute "sudo localectl set-keymap de-latin1-nodeadkeys" "setting up locale keymap as de-latin1-nodeadkeys"

log-execute "sudo systemctl enable firewalld" "firewalld: enabling"
log-execute "sudo systemctl start firewalld" "firewalld: starting"
log-execute "sudo firewall-cmd --permanent --add-interface=eth0 --zone=trusted" "firewalld: setting interface eth0 zone on trusted"
log-execute "sudo firewall-cmd --permanent --zone=trusted --set-target=ACCEPT" "firewalld: setting trusted zone target on ACCEPT"
log-execute "sudo firewall-cmd --permanent --add-interface=eth1 --zone=public" "firewalld: setting interface eth1 zone on public"
log-execute "sudo firewall-cmd --permanent --add-interface=virbr0 --zone=public" "firewalld: setting interface virbr0 zone on public"
log-execute "sudo firewall-cmd --permanent --zone=public --set-target=ACCEPT" "firewalld: setting public zone target on ACCEPT"

log-execute "sudo firewall-cmd --reload" "firewalld: reloading configuration"

log-progress-nl "done"
