#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env

export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET="$( $BOSH_CMD int "$ALIAS_DIRECTORY"/concourse-vars.yml --path /concourse_to_credhub_secret )"
export CREDHUB_SERVER="$CONCOURSE_EXTERNAL_URL:8844"
export CREDHUB_CA_CERT="$( $BOSH_CMD int "$ALIAS_DIRECTORY"/concourse-vars.yml --path /credhub-ca/ca )"

$CREDHUB_CMD login

# logs into credhub
