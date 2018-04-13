#!/bin/bash -e

###
# Description:
#   Loads the environment based on the `FOUNDATION` environment variable;
#     otherwise, loads the env file
#
# Usage:
#   source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh
##

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

export BOSH_CMD=bosh
export VAULT_CMD=vault
export JQ_CMD=jq
export CREDHUB_CMD=credhub

if [[ "$ENV" != "" ]]; then
  echo "sourcing $__DIR__/$ENV-env...."
  source "$__DIR__"/$ENV-env
else
  echo "sourcing $__DIR__/.env...."
  source "$__DIR__"/.env
fi

UNAME=$(uname)
if [[ "$UNAME" == "Darwin" ]]; then
  DNS_SERVERS_LIST=( $(echo "$DNS_SERVERS" | $JQ_CMD -r '.[]') )
  networksetup -setdnsservers Wi-Fi $DNS_SERVERS_LIST
fi

export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY

if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  printf -v NO_PROXY '%s,' $(eval echo $NO_PROXY_PATTERN)
  export NO_PROXY
  export no_proxy=$NO_PROXY
fi
