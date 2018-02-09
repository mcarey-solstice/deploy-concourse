#!/bin/bash

$BOSH_CMD -e $BOSH_ALIAS -n upload-release $UAA_RELEASE_URL

$BOSH_CMD -e $BOSH_ALIAS -n upload-release $CREDHUB_RELEASE_URL
