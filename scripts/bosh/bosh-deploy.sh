#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../helpers
source "$__DIR__"/../load-env

log "Deploying bosh"

log "Calling bosh-create-env"
"$__DIR__"/bosh-create-env.sh

log "Logging into bosh"
"$__DIR__"/bosh-login.sh

log "Calling bosh-update-cloud-config"
"$__DIR__"/bosh-update-cloud-config.sh

# deploys bosh
