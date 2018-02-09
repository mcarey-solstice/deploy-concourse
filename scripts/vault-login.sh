#!/bin/bash

if [[ "$FOUNDATION" != "" ]]; then
  echo "sourcing $PWD/scripts/$FOUNDATION-env...."
  source $PWD/scripts/$FOUNDATION-env
else
  echo "sourcing $PWD/env...."
  source $PWD/scripts/env
fi

export VAULT_TOKEN=$(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD login $VAULT_TOKEN
