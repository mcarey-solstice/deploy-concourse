#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh

export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /concourse_to_credhub_secret)
export CREDHUB_SERVER=$CONCOURSE_EXTERNAL_URL:8844
export CREDHUB_CA_CERT=$(bosh int $PWD/$BOSH_ALIAS/concourse-vars.yml --path /credhub-ca/ca)

credhub api
