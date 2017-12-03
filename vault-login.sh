#!/bin/bash

source ./env

networksetup -setdnsservers Wi-Fi $DNS_SERVERS

export VAULT_TOKEN=$(cat ./$BOSH_ALIAS/vault.log | grep 'Initial Root Token' | awk '{print $4}')
$VAULT_CMD auth $VAULT_TOKEN
