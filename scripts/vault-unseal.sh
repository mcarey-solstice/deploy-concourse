#!/bin/bash

if [[ "$FOUNDATION" != "" ]]; then
  echo "sourcing $PWD/scripts/$FOUNDATION-env...."
  source $PWD/scripts/$FOUNDATION-env
else
  echo "sourcing $PWD/env...."
  source $PWD/scripts/env
fi

export VAULT_ADDR=$1

set +x
export VAULT_TOKEN=$(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')

$VAULT_CMD operator unseal $(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Unseal Key 1' | awk '{print $4}')
$VAULT_CMD operator unseal $(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Unseal Key 2' | awk '{print $4}')
$VAULT_CMD operator unseal $(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Unseal Key 3' | awk '{print $4}')
set -x
