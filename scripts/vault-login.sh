#!/bin/bash

if [ -z "$__BASEDIR__" ]; then
  export __DIR__="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  source $__DIR__/scripts/load-env.sh
fi

export VAULT_TOKEN=$(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD login $VAULT_TOKEN
