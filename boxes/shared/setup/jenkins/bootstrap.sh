#!/usr/bin/env bash

source /tmp/common.sh

jdk_package="java-1.8.0-openjdk"

log-progress-nl "begin"

log-execute "sudo yum install ${jdk_package}" "install ${jdk_package}"

log-progress-nl "setup ${jdk_package}"
sudo cat > /etc/profile.d/java.sh <<EOL
export JAVA_HOME="/usr/lib/jvm/jre"
export JRE_HOME="/usr/lib/jvm/jre"
EOL

log-progress-nl "done"
