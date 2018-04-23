#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../load-env

CONCOURSE_DEPLOYMENT_DIRECTORY="$VENDOR_DIRECTORY"/concourse-deployment

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d concourse -n --force

# deletes concourse
