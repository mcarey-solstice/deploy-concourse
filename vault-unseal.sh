#!/bin/bash -ex

source $PWD/env
export VAULT_ADDR=$1

networksetup -setdnsservers Wi-Fi $DNS_SERVERS

set +x
export VAULT_TOKEN=$(cat ./$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')

$VAULT_CMD unseal $(cat ./$BOSH_ALIAS/vault.log | grep 'Unseal Key 1' | awk '{print $4}')
$VAULT_CMD unseal $(cat ./$BOSH_ALIAS/vault.log | grep 'Unseal Key 2' | awk '{print $4}')
$VAULT_CMD unseal $(cat ./$BOSH_ALIAS/vault.log | grep 'Unseal Key 3' | awk '{print $4}')
set -x
