#!/bin/bash

if [[ "$ENV" != "" ]]; then
  echo "sourcing $DIR/$ENV-env...."
  source $PWD/scripts/$ENV-env
else
  echo "sourcing $DIR/.env...."
  source $PWD/scripts/.env
fi

export VAULT_TOKEN=$(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD login $VAULT_TOKEN
