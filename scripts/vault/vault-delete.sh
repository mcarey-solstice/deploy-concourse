#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d vault -n --force

# deletes vault
