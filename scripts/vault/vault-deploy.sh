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

log "Deploying Vault"
$BOSH_CMD -n \
  -e $BOSH_ALIAS \
  -d vault \
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
_HEALTH=$( curl -m 10 -s $VAULT_ADDR/v1/sys/health )
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

if [ "$VAULT_LDAP_ENABLED" = "true" ]; then
  if [ -n "$VAULT_LDAP_INSECURE_TLS" ]; then
    LDAP_PARAMS+=" insecure_tls=$VAULT_LDAP_INSECURE_TLS"
  fi
  if [ -n "$VAULT_LDAP_BINDDN" ]; then
    LDAP_PARAMS+=" binddn=$VAULT_LDAP_BINDDN"
  fi
  if [ -n "$VAULT_LDAP_USERDN" ]; then
    LDAP_PARAMS+=" userdn=$VAULT_LDAP_USERDN"
  fi
  if [ -n "$VAULT_LDAP_BINDPASS" ]; then
    LDAP_PARAMS+=" bindpass=$VAULT_LDAP_BINDPASS"
  fi
  if [ -n "$VAULT_LDAP_USERATTR" ]; then
    LDAP_PARAMS+=" userattr=$VAULT_LDAP_USERATTR"
  fi
  if [ -n "$VAULT_LDAP_GROUPATTR" ]; then
    LDAP_PARAMS+=" groupattr=$VAULT_LDAP_GROUPATTR"
  fi
  if [ -n "$VAULT_LDAP_STARTTLS" ]; then
    LDAP_PARAMS+=" starttls=$VAULT_LDAP_STARTTLS"
  fi
  if [ -n "$VAULT_LDAP_CERTIFICATE" ]; then
    LDAP_PARAMS+=" certificate=$VAULT_LDAP_CERTIFICATE"
  fi
  if [ -n "$VAULT_LDAP_DISCOVERDN" ]; then
    LDAP_PARAMS+=" discoverdn=$VAULT_LDAP_DISCOVERDN"
  fi
  if [ -n "$VAULT_LDAP_DENY_NULL_BIND" ]; then
    LDAP_PARAMS+=" deny_null_bind=$VAULT_LDAP_DENY_NULL_BIND"
  fi
  if [ -n "$VAULT_LDAP_UPNDOMAIN" ]; then
    LDAP_PARAMS+=" upndomain=$VAULT_LDAP_UPNDOMAIN"
  fi
  if [ -n "$VAULT_LDAP_GROUPFILTER" ]; then
    LDAP_PARAMS+=" groupfilter=$VAULT_LDAP_GROUPFILTER"
  fi

  $VAAULT_CMD auth enable ldap
  $VAULT_CMD write auth/ldap/config \
    url="$VAULT_LDAP_URL" \
    groupdn="$VAULT_LDAP_GROUPDN" \
    $LDAP_PARAMS
fi

log "Updating policy: $VAULT_POLICY_NAME"
$VAULT_CMD policy write "$VAULT_POLICY_NAME" "$__BASEDIR__"/vault/vault-policy.hcl

_MOUNT="${CONCOURSE_PATH_PREFIX#/}"/
if [ "$( $VAULT_CMD secrets list -format=json | $JQ_CMD -r "has(\"$_MOUNT\")" )" = "false" ]; then
  log "Creating mount: $CONCOURSE_PATH_PREFIX"
  # Create a mount for concourse
  $VAULT_CMD secrets enable -path="$CONCOURSE_PATH_PREFIX" -description="Secrets for use by concourse pipelines" generic
fi

function _create_token() {
  echo "Creating token"
  $VAULT_CMD token create --policy="$VAULT_POLICY_NAME" -period="87600h" -format=json > "$VAULT_TOKEN_FILE"
}

# Create application policy
_status=0
_CLIENT_TOKEN="$( get_client_token )" || _status=$? && :
if [ $_status -ne 0 ]; then
  _create_token
else
  # Check the token is legit
  $VAULT_CMD token lookup "$_CLIENT_TOKEN" || _status=$? && :
  if [ $_status -ne 0 ]; then
    # Bad token
    _create_token
  fi
fi

if [ -n "$VAULT_POLICY_DIRECTORY" ]; then
  log "Looking for policies in $VAULT_POLICY_DIRECTORY"
  for i in $VAULT_POLICY_DIRECTORY/*.hcl; do
    POLICY_NAME="$( basename $i .hcl )"
    log "Adding policy: $POLICY_NAME"
    $VAULT_CMD policy write "$POLICY_NAME" "$i"
  done
fi

# deploys vault
