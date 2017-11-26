#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"
log-execute "yum -y update" "updating system software"
log-execute "yum -y upgrade" "upgrading system software"
log-progress-nl "done"
