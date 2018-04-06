#!/bin/bash

if [[ "$ENV" != "" ]]; then
  echo "sourcing $DIR/$ENV-env...."
  source $PWD/scripts/$ENV-env
else
  echo "sourcing $DIR/.env...."
  source $PWD/scripts/.env
fi

export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /concourse_to_credhub_secret)
export CREDHUB_SERVER=$CONCOURSE_EXTERNAL_URL:8844
export CREDHUB_CA_CERT=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /credhub-ca/ca)

credhub api
