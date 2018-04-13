#!/bin/bash

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $__DIR__/load-env.sh

__BASEDIR__=$(dirname $__DIR__)
export VAULT_ADDR=$1

set +x
export VAULT_TOKEN=$(cat $__BASEDIR__/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')

$VAULT_CMD operator unseal $(cat $__BASEDIR__/$BOSH_ALIAS/vault.log | grep 'Unseal Key 1' | awk '{print $4}')
$VAULT_CMD operator unseal $(cat $__BASEDIR__/$BOSH_ALIAS/vault.log | grep 'Unseal Key 2' | awk '{print $4}')
$VAULT_CMD operator unseal $(cat $__BASEDIR__/$BOSH_ALIAS/vault.log | grep 'Unseal Key 3' | awk '{print $4}')
set -x
