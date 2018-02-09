#!/bin/bash

if [[ "$FOUNDATION" != "" ]]; then
  echo "sourcing $PWD/scripts/$FOUNDATION-env...."
  source $PWD/scripts/$FOUNDATION-env
else
  echo "sourcing $PWD/env...."
  source $PWD/scripts/env
fi

export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /concourse_to_credhub_secret)
export CREDHUB_SERVER=$CONCOURSE_EXTERNAL_URL:8844
export CREDHUB_CA_CERT=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /atc_tls/ca)

$CREDHUB_CMD api
