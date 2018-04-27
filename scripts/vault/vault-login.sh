#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env
source "$__DIR__"/vault-helpers

$VAULT_CMD login token=$VAULT_TOKEN

# logs into vault
