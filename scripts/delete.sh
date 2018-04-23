#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/helpers
source "$__DIR__"/load-env

"$__DIR__"/concourse/concourse-delete.sh

if [ -n "$CREDENTIAL_MANAGER" ]; then
  "$__DIR__/$CREDENTIAL_MANAGER/$CREDENTIAL_MANAGER-delete.sh"
fi

"$__DIR__"/bosh/bosh-delete.sh

rm -rf "$ALIAS_DIRECTORY"
rm -rf "$VENDOR_DIRECTORY"


# deletes everything
