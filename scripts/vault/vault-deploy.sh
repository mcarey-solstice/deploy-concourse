#!/bin/bash -e

declare -r __DIR__="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"

source "$__DIR__"/../load-env
source "$__DIR__"/../releases consul vault
source "$__DIR__"/vault-helpers

# Upload the releases
$BOSH_CMD -e $BOSH_ALIAS -n upload-release $CONSUL_RELEASE_URL
$BOSH_CMD -e $BOSH_ALIAS -n upload-release $VAULT_RELEASE_URL

# Vault certs
VAULT_TLS_FLAGS="--vars-store $ALIAS_DIRECTORY/vault-vars.yml"
if [ -n "$VAULT_SERVER_CERT_FILENAME" ]; then
  VAULT_TLS_FLAGS="--var-file vault-tls.certificate=$VAULT_SERVER_CERT_FILENAME --var-file vault-tls.private_key=$VAULT_PRIVATE_KEY_FILENAME"
  log "Using provided Vault cert"
else
  log "Generating cert for Vault"
fi

$BOSH_CMD -n \
  -e $BOSH_ALIAS \
  -d $VAULT_CMD \
  deploy $__BASEDIR__/vault/vault.yml \
    -v VAULT_AZ_NAME=$VAULT_AZ_NAME \
    -v VAULT_NW_NAME=$VAULT_NW_NAME \
    -v STATIC_IPS=$VAULT_STATIC_IPS \
    -v VAULT_INSTANCES=$VAULT_INSTANCES \
    -v VAULT_VM_TYPE=$VAULT_VM_TYPE \
    -v VAULT_DISK_TYPE=$VAULT_DISK_TYPE \
    -v LOAD_BALANCER_URL=$VAULT_LOAD_BALANCER_URL \
    -v VAULT_TCP_PORT=$VAULT_TCP_PORT \
    $VAULT_TLS_FLAGS

# Configure
_HEALTH=$( curl --fail -m 10 -s $VAULT_ADDR/v1/sys/health )
_INITIALIZED="$( echo "$_HEALTH" | $JQ_CMD '.initialized' )"
if [ "$_INITIALIZED" = "false" ]; then
  log "Initalizing Vault"
  $VAULT_CMD init > "$VAULT_LOG"
fi

_SEALED="$( echo "$_HEALTH" | $JQ_CMD '.sealed' )"
if [ "$_SEALED" = "true" ]; then
  log "Unsealing Vault"
  "$__DIR__"/vault-unseal.sh
fi

log "Updating policy: $VAULT_POLICY_NAME"
$VAULT_CMD policy write "$VAULT_POLICY_NAME" "$__BASEDIR__"/vault/vault-policy.hcl

_MOUNT="${CONCOURSE_VAULT_MOUNT#/}"/
if [ "$( $VAULT_CMD secrets list -format=json | $JQ_CMD -r "has(\"$_MOUNT\")" )" = "false" ]; then
  log "Creating mount: $CONCOURSE_VAULT_MOUNT"
  # Create a mount for concourse
  $VAULT_CMD secrets enable -path="$CONCOURSE_VAULT_MOUNT" -description="Secrets for use by concourse pipelines" generic
fi

function _create_token() {
  $VAULT_CMD token create --policy="$VAULT_POLICY_NAME" -period="87600h" -format=json > "$VAULT_TOKEN_FILE"
}

# Create application policy
_status=0
_CLIENT_TOKEN="$( get_client_token )" || _status=$?
if [ $_status -ne 0 ]; then
  _create_token
else
  # Check the token is legit
  $VAULT_CMD token lookup "$_CLIENT_TOKEN" || _status=$?
  if [ $_status -ne 0 ]; then
    # Bad token
    _create_token
  fi
fi

# deploys vault
