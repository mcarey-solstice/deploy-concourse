#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../load-env

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET="$( $BOSH_CMD int "$ALIAS_DIRECTORY"/creds.yml --path /admin_password )"

$BOSH_CMD \
  -e "$BOSH_IP" \
  --ca-cert <( $BOSH_CMD int "$ALIAS_DIRECTORY"/creds.yml --path /director_ssl/ca ) \
  alias-env \
    "$BOSH_ALIAS"

$BOSH_CMD -e "$BOSH_ALIAS" login

# bosh.login
