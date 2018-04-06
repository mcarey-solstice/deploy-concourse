#!/bin/bash -e

if [[ "$ENV" != "" ]]; then
  echo "sourcing $DIR/$ENV-env...."
  source $PWD/scripts/$ENV-env
else
  echo "sourcing $DIR/.env...."
  source $PWD/scripts/.env
fi

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /admin_password`

$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS
