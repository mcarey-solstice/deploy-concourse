#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh

export VAULT_TOKEN=$(cat $PWD/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD login $VAULT_TOKEN
