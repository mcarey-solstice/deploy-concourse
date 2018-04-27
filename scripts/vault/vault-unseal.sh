#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env
source "$__DIR__"/vault-helpers

_ips="$( $BOSH_CMD -e $BOSH_ALIAS vms -d vault --json | jq -r '.Tables[0].Rows[] | .ips' )"
for ip in $_ips; do
  log "Unsealing $ip"
  i=1
  for key in $VAULT_UNSEAL_KEYS; do
    log "Using unseal key $i"
    i=$((i+1))
    _json="$( VAULT_ADDR=http://$ip vault unseal -format=json "$key" )"
    if [ "$( echo "$_json" | $JQ_CMD '.sealed' )" = "false" ]; then
      log "$ip is unsealed"
      break
    fi
  done
done
