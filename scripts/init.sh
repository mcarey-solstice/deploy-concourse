#!/bin/bash

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$ENV" != "" ]]; then
  echo "sourcing $DIR/$ENV-env...."
  source $DIR/$ENV-env
else
  echo "sourcing $DIR/.env...."
  source $DIR/.env
fi
