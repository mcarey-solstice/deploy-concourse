#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env
source "$__DIR__"/../releases consul

$BOSH_CMD -e $BOSH_ALIAS -n upload-release $CONSUL_RELEASE_URL

# deploys consul
