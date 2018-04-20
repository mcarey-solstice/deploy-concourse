#!/bin/bash

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
__BASEDIR__=$(dirname $__DIR__)

source "$__DIR__"/../load-env

CONCOURSE_DEPLOYMENT_DIRECTORY="$VENDOR_DIRECTORY"/concourse-deployment

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d concourse -n --force

# deletes concourse
