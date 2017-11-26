#!/usr/bin/env bash

if [ "$(hostname -d)" == "prd.lan" ]; then
  stage="prd"
  lan_prefix="172.16.10"
else
  stage="dev"
  lan_prefix="172.16.20"
fi

cat > file <<EOL
Content
EOL
