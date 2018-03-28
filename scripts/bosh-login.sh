#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /admin_password`

$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS
