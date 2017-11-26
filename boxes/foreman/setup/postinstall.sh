#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"
log-progress-nl "sudo cat /var/lib/puppet/ssl/certs/ca.pem"
log-execute "sudo reboot" "rebooting ${hostname} - please stand by."
log-progress-nl "done"
