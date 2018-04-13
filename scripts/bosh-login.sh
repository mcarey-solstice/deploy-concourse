#!/bin/bash -e

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $__DIR__/load-env.sh

__BASEDIR__=$(dirname $__DIR__)
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $__BASEDIR__/$BOSH_ALIAS/creds.yml --path /admin_password`

$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $__BASEDIR__/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS
