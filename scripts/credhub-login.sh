#!/bin/bash

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
__BASEDIR__=$(dirname $__DIR__)

source $__DIR__/load-env.sh
export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET=$(bosh int $__BASEDIR__/$BOSH_ALIAS/concourse-vars.yml --path /concourse_to_credhub_secret)
export CREDHUB_SERVER=$CONCOURSE_EXTERNAL_URL:8844
export CREDHUB_CA_CERT=$(bosh int $__BASEDIR__/$BOSH_ALIAS/concourse-vars.yml --path /credhub-ca/ca)

credhub api
