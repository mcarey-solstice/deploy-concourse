#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/releases

$BOSH_CMD -e $BOSH_ALIAS -n upload-release $UAA_RELEASE_URL

$BOSH_CMD -e $BOSH_ALIAS -n upload-release $CREDHUB_RELEASE_URL
