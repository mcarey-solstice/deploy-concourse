#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../helpers
source "$__DIR__"/../load-env

"$__DIR__"/bosh/bosh-deploy.sh

if [ -n "$CREDENTIAL_MANAGER" ]; then
  log "Credential manager is $CREDENTIAL_MANAGER."
  "$__DIR__/$CREDENTIAL_MANAGER/$CREDENTIAL_MANAGER-deploy.sh"
else
  log "No credential manager configured"
fi

"$__DIR__"/concourse/concourse-deploy.sh

# deploys everything
