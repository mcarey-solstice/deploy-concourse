#!/bin/bash

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $__DIR__/load-env.sh

__BASEDIR__=$(dirname $__DIR__)
export VAULT_TOKEN=$(cat $__BASEDIR__/$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD login $VAULT_TOKEN
