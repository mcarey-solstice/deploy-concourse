#!/bin/bash -e

###
# Description:
#   Loads the environment based on the `FOUNDATION` environment variable;
#     otherwise, loads the env file
#
# Usage:
#   source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh
##

if [ -z "$__DIR__" ]; then
  __BASEDIR__="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
else
  __BASEDIR__="$__DIR__"
fi

export BOSH_CMD=bosh
export VAULT_CMD=vault
export JQ_CMD=jq
export CREDHUB_CMD=credhub

if [[ "$ENV" != "" ]]; then
  echo "sourcing $__BASEDIR__/scripts/$ENV-env...."
  source "$__BASEDIR__"/scripts/$ENV-env
else
  echo "sourcing $__BASEDIR__/.env...."
  source "$__BASEDIR__"/scripts/.env
fi

UNAME=$(uname)
if [[ "$UNAME" == "Darwin" && "$CREDENTIAL_MANAGER" == "vault" ]]; then
  networksetup -setdnsservers Wi-Fi $DNS_SERVERS
fi

export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY

if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  printf -v NO_PROXY '%s,' $(eval echo $NO_PROXY_PATTERN)
  export NO_PROXY
  export no_proxy=$NO_PROXY
fi
