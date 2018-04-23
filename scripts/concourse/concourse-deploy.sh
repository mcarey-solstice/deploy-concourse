#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../helpers
source "$__DIR__"/../load-env
source "$__DIR__"/../releases concourse stemcell garden_runc os_conf

CONCOURSE_DEPLOYMENT_DIRECTORY="$( git_submodule concourse-deployment )"

STEMCELL_FILE="$VENDOR_DIRECTORY/$( basename $STEMCELL_URL )"
if [ ! -f "$STEMCELL_FILE" ]; then
  log "Getting stemcell"
  wget -O "$STEMCELL_FILE" "$STEMCELL_URL"
fi

log "Uploading stemcell"
$BOSH_CMD -e "$BOSH_ALIAS" -n upload-stemcell "$STEMCELL_FILE"

CONCOURSE_DEPLOYMENT_OPS_FILES=" "
CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS=" "

if [ "$CREDENTIAL_MANAGER" == "credhub" ]; then
  log "Credential manager selected is credhub"
  "$__DIR__"/../credhub/credhub-deploy.sh

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $__BASEDIR__/credhub/add-credhub.yml \
        -o $__BASEDIR__/ops-files/credhub-tls-cert-verify.yml"

  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v insecure_skip_verify=$INSECURE_SKIP_VERIFY \
      -v concourse_path_prefix=$CONCOURSE_PATH_PREFIX \
      -v uaa_release_version=$UAA_RELEASE_VERSION \
      -v credhub_release_version=$CREDHUB_RELEASE_VERSION"

elif [ "$CREDENTIAL_MANAGER" = "vault" ]; then
  log "Credential manager selected is vault"
  "$__DIR__"/../vault/vault-deploy.sh

  CLIENT_TOKEN="( source "$__DIR__"/../vault/vault-helpers && get_client_token )"

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $__BASEDIR__/vault/add-vault.yml \
        -o $__BASEDIR__/ops-files/vault-tls-cert-verify.yml"
  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v vault_addr=$VAULT_ADDR \
      -v client_token=$CLIENT_TOKEN \
      -v concourse_path_prefix=$CONCOURSE_PATH_PREFIX \
      -v insecure_skip_verify=$INSECURE_SKIP_VERIFY"
else
  log "Skipping integration with any credential manager"
fi

if [ "$CONCOURSE_RELEASES_LATEST" ]; then
  log "Using versions from concourse-deployment's versions.yml for concourse, garden runc, and postgres"
  CONCOURSE_VERSIONS_TO_DEPLOY="-o $CONCOURSE_DEPLOYMENT_DIRECTORY/versions.yml"
else
  log "Using versions from environment for concourse, garden runc, and postgres"
  CONCOURSE_VERSIONS_TO_DEPLOY="-v concourse_version=$CONCOURSE_RELEASE_VERSION \
    -v concourse_sha1=$CONCOURSE_RELEASE_SHA \
    -v garden_runc_version=$GARDEN_RUNC_RELEASE_VERSION \
    -v garden_runc_sha1=$GARDEN_RUNC_RELEASE_SHA \
    -v postgres_version=$POSTGRES_RELEASE_VERSION \
    -v postgres_sha1=$POSTGRES_RELEASE_SHA"
fi

TLS_OPS_FILES=" -o ops-files/add-tls-vars.yml"
TLS_VARS=" "
if [ -n "$CONCOURSE_TLS_CERT_FILE" -a -n "$CONCOURSE_TLS_KEY_FILE" ]; then
  TLS_OPS_FILES=" -o ops-files/add-tls-cert-vars.yml"
  TLS_VARS=" --var-file=tls_cert=$CONCOURSE_TLS_CERT_FILE \
      --var-file=tls_key=$CONCOURSE_TLS_KEY_FILE"
fi

HTTP_PROXY_OPS_FILES=" "
HTTP_PROXY_VARS=" "
if [ "$HTTP_PROXY_REQUIRED" = "true" ]; then
  HTTP_PROXY_OPS_FILES=" -o $CONCOURSE_DEPLOYMENT_DIRECTORY/cluster/operations/http-proxy.yml "
  HTTP_PROXY_VARS=" -v proxy_url=$HTTP_PROXY \
    -v no_proxy=[$NO_PROXY] "
fi

log "Deploying concourse"
$BOSH_CMD -n \
  -e "$BOSH_ALIAS" \
  deploy "$CONCOURSE_DEPLOYMENT_DIRECTORY"/cluster/concourse.yml \
    -d concourse \
    $CONCOURSE_VERSIONS_TO_DEPLOY \
    -o "$__BASEDIR__"/ops-files/nws-azs.yml \
    -o "$CONCOURSE_DEPLOYMENT_DIRECTORY"/cluster/operations/scale.yml \
    -o "$CONCOURSE_DEPLOYMENT_DIRECTORY"/cluster/operations/basic-auth.yml \
    -o "$CONCOURSE_DEPLOYMENT_DIRECTORY"/cluster/operations/tls.yml \
    $TLS_OPS_FILES $TLS_VARS \
    --vars-store="$ALIAS_DIRECTORY"/concourse-vars.yml \
    -v atc_basic_auth.username="$CONCOURSE_ADMIN_USERNAME" \
    -v atc_basic_auth.password="$CONCOURSE_ADMIN_PASSWORD" \
    -v tls_bind_port="$TLS_BIND_PORT" \
    -v deployment_name=concourse \
    -v az_name="$CONCOURSE_AZ_NAME" \
    -v network_name="$CONCOURSE_NW_NAME" \
    -v web_network_name="$CONCOURSE_NW_NAME" \
    -v web_static_ips="$CONCOURSE_WEB_STATIC_IPS" \
    -v concourse_db_ip="$CONCOURSE_DB_STATIC_IPS" \
    -v worker_static_ips="$CONCOURSE_WORKER_STATIC_IPS" \
    -v concourse_fqdn="$CONCOURSE_FQDN" \
    -v external_url="$CONCOURSE_EXTERNAL_URL" \
    -v web_instances="$ATC_WEB_INSTANCES" \
    -v web_vm_type="$ATC_WEB_VM_TYPE" \
    -v db_instances="$CONCOURSE_DB_INSTANCES" \
    -v db_vm_type="$CONCOURSE_DB_VM_TYPE" \
    -v db_persistent_disk_type="$CONCOURSE_DB_PERSISTENT_DISK_TYPE" \
    -v worker_instances="$CONCOURSE_WORKER_INSTANCES" \
    -v worker_vm_type="$CONCOURSE_WORKER_VM_TYPE" \
    -v skip_ssl_validation="$INSECURE_SKIP_VERIFY" \
    $CONCOURSE_DEPLOYMENT_OPS_FILES $CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS \
    $HTTP_PROXY_OPS_FILES $HTTP_PROXY_VARS

# deploys concourse
