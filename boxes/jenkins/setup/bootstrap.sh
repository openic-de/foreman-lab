#!/usr/bin/env bash

sudo yum -y update && yum -y upgrade

cat >file <<EOL
Content
EOL
