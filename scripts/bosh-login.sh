#!/bin/bash -e

if [ -z "$__BASEDIR__" ]; then
  __DIR__="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  source $__DIR__/scripts/load-env.sh
fi

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /admin_password`

$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS
