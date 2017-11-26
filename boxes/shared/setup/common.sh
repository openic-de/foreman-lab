#!/usr/bin/env bash

phase=${1}
component=${2}
hostname=$(hostname -s)
domainname=$(hostname -d)

function log {
  message=${1}
  printf "${message}"
}

function log-nl {
  message=${1}
  printf "${message}\n"
}

function log-progress {
  message=${1}
  log "${phase} ${component}: ${message}"
}

function log-progress-nl {
  message=${1}
  log-nl "${phase} ${component}: ${message}"
}

utilities="parallel coreutils findutils patchutils"

sudo rpm -q ${utilities} 2>&1 >/dev/null; rc=${?}
if [ ${rc} -ne 0 ]; then
  log-nl "installing utilities"
  output=$(sudo yum -y install ${utilities} 2>&1)
  rc=${?}
  if [ ${rc} -ne 0 ]; then
    log-nl "${red}error: ${output}"
    return ${rc}
  fi
fi

black="\e[30m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
magenta="\e[35m"
cyan="\e[36m"
white="\e[37m"
reset="\e[0m"

function log-execute {
  what=${1}
  why=${2}

  log-progress-nl "${why} - execute"

  output=$(${what} 2>&1);

  rc=${?}

  if [ ${rc} -eq 0 ]; then
    log-progress-nl "${why} - success (0)"
  else
    log-progress-nl "${why} - ${red}failed${reset}  (${rc})"
    log-progress-nl "\t'${what}' output:"
    log-progress-nl "\t${output}"
  fi

  return ${rc}
}

function log-execute-show-output {
  what=${1}
  why=${2}

  log-progress-nl "${why} - execute"

  ${what}

  rc=${?}

  if [ ${rc} -eq 0 ]; then
    log-progress-nl "${why} - success (0)"
  else
    log-progress-nl "${why} - ${red}failed${reset}  (${rc})"
    log-progress-nl "\t'${what}' output: see abouve"
  fi

  return ${rc}
}
