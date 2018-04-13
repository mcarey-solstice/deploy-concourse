#!/bin/bash -e

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
__BASEDIR__=$(dirname $__DIR__)

source $__DIR__/load-env.sh
source $__DIR__/releases

mkdir -p $__BASEDIR__/$BOSH_ALIAS

if [ ! -d "$__BASEDIR__/bosh-deployment" ]; then
  git clone https://github.com/cloudfoundry/bosh-deployment $__BASEDIR__/bosh-deployment
else
  echo "pulling bosh-deployment repo"
  cd $__BASEDIR__/bosh-deployment && git pull && cd -
fi

HTTP_PROXY_OPS_FILES=" "
HTTP_PROXY_VARS=" "
if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  HTTP_PROXY_OPS_FILES=" -o $__BASEDIR__/bosh-deployment/misc/proxy.yml "
  HTTP_PROXY_VARS=" -v http_proxy=$HTTP_PROXY \
        -v https_proxy=$HTTPS_PROXY \
        -v no_proxy=$NO_PROXY "
fi

$BOSH_CMD create-env $__BASEDIR__/bosh-deployment/bosh.yml \
  --state=$__BASEDIR__/$BOSH_ALIAS/state.json \
  --vars-store=$__BASEDIR__/$BOSH_ALIAS/creds.yml \
  -o $__BASEDIR__/bosh-deployment/vsphere/cpi.yml \
  -o $__BASEDIR__/bosh-deployment/vsphere/resource-pool.yml \
  -o $__BASEDIR__/bosh-deployment/jumpbox-user.yml \
  -o $__BASEDIR__/bosh-deployment/uaa.yml \
  -o $__BASEDIR__/ops-files/versions.yml \
  -o $__BASEDIR__/ops-files/dns.yml \
  -v director_name="$BOSH_ALIAS" \
  -v internal_cidr="$NETWORK_CIDR" \
  -v internal_gw="$NETWORK_GATEWAY" \
  -v internal_ip="$BOSH_IP" \
  -v dns_servers="$DNS_SERVERS" \
  -v network_name="$VCENTER_NETWORK_NAME" \
  -v vcenter_dc="$VSPHERE_DATACENTER" \
  -v vcenter_ds="$VCENTER_STORAGE_NAME" \
  -v vcenter_ip="$VCENTER_IP" \
  -v vcenter_user="$VCENTER_USERNAME" \
  -v vcenter_password="$VCENTER_PASSWORD" \
  -v vcenter_templates="$VCENTER_VM_TEMPLATES_FOLDER_NAME" \
  -v vcenter_vms="$VCENTER_VMS_FOLDER_NAME" \
  -v vcenter_disks="$VCENTER_DISK_FOLDER_NAME" \
  -v vcenter_cluster="$VCENTER_CLUSTER_NAME" \
  -v vcenter_rp="$VCENTER_RESOURCE_POOL" \
  -v bosh_release_url="$BOSH_RELEASE_URL" \
  -v bosh_release_sha="$BOSH_RELEASE_SHA" \
  -v vsphere_cpi_release_url="$VSPHERE_CPI_URL" \
  -v vsphere_cpi_release_sha="$VSPHERE_CPI_SHA" \
  -v stemcell_url="$STEMCELL_URL" \
  -v stemcell_sha="$STEMCELL_SHA" \
  -v os_conf_release_url="$OS_CONF_RELEASE_URL" \
  -v os_conf_release_sha="$OS_CONF_RELEASE_SHA" \
  -v uaa_release_url="$UAA_RELEASE_URL" \
  -v uaa_release_sha="$UAA_RELEASE_SHA" \
  $HTTP_PROXY_OPS_FILES $HTTP_PROXY_VARS

source $__BASEDIR__/scripts/bosh-login.sh

$BOSH_CMD -e $BOSH_ALIAS -n update-cloud-config $__BASEDIR__/cloud-configs/cloud-config.yml \
  -v az_name="$CONCOURSE_AZ_NAME" \
  -v nw_name="$CONCOURSE_NW_NAME" \
  -v vcenter_cluster="$VCENTER_CLUSTER_NAME" \
  -v network_cidr="$NETWORK_CIDR" \
  -v network_name="$VCENTER_NETWORK_NAME" \
  -v network_gateway="$NETWORK_GATEWAY" \
  -v dns_servers="$DNS_SERVERS" \
  -v reserved_ips="$RESERVED_IPS" \
  -v static_ips="$CLOUD_CONFIG_STATIC_IPS" \
  -v vcenter_rp="$VCENTER_RESOURCE_POOL" \
  -v vm_disk_type="$VM_DISK_TYPE"

if [ ! -d "$__BASEDIR__/concourse-deployment" ]; then
  git clone https://github.com/concourse/concourse-deployment $__BASEDIR__/concourse-deployment
else
  cd $__BASEDIR__/concourse-deployment && git pull && cd -
fi

if [[ ! -f "bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz" ]]; then
  rm -f bosh-stemcell-*.tgz
  wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz
fi

$BOSH_CMD -e $BOSH_ALIAS -n upload-stemcell bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz

CONCOURSE_DEPLOYMENT_OPS_FILES=" "
CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS=" "

if [[ "$CREDENTIAL_MANAGER" == "credhub" ]]; then
  echo "Credential manager selected is credhub"
  source $__BASEDIR__/scripts/deploy_credhub.sh

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $__BASEDIR__/credhub/add-credhub.yml \
        -o $__BASEDIR__/ops-files/credhub-tls-cert-verify.yml"

  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v insecure_skip_verify=$INSECURE_SKIP_VERIFY \
      -v concourse_path_prefix=$CONCOURSE_PATH_PREFIX -v uaa_release_version=$UAA_RELEASE_VERSION\
      -v credhub_release_version=$CREDHUB_RELEASE_VERSION"

elif [[ "$CREDENTIAL_MANAGER" == "vault" ]]; then
  echo "Credential manager selected is vault"
  source $__BASEDIR__/scripts/deploy_vault.sh

  CLIENT_TOKEN=$(cat $__BASEDIR__/$BOSH_ALIAS/create_token_response.json | $JQ_CMD .auth.client_token | tr -d '"')

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $__BASEDIR__/vault/add-vault.yml \
        -o $__BASEDIR__/ops-files/vault-tls-cert-verify.yml"
  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v vault_addr=$VAULT_ADDR \
      -v client_token=$CLIENT_TOKEN \
      -v concourse_path_prefix=$CONCOURSE_PATH_PREFIX \
      -v insecure_skip_verify=$INSECURE_SKIP_VERIFY"
  # -v BACKEND_ROLE=$BACKEND_ROLE \
  # -v ROLE_ID=$ROLE_ID \
  # -v SECRET_ID=$SECRET_ID
else
  echo "Skipping integration with any credential manager"
fi

if [[ "$CONCOURSE_RELEASES_LATEST" == "false" ]]; then
  CONCOURSE_VERSIONS_TO_DEPLOY="-o $__BASEDIR__/concourse-deployment/versions.yml"
else
  CONCOURSE_VERSIONS_TO_DEPLOY="-o $__BASEDIR__/ops-files/concourse-versions.yml \
    -v concourse_release_version=$CONCOURSE_RELEASE_VERSION \
    -v garden_runc_release_version=$GARDEN_RUNC_RELEASE_VERSION \
    -v postgres_release_version=$POSTGRES_RELEASE_VERSION"
  $BOSH_CMD -e $BOSH_ALIAS -n upload-release $CONCOURSE_RELEASE_URL
  $BOSH_CMD -e $BOSH_ALIAS -n upload-release $GARDEN_RUNC_RELEASE_URL
  $BOSH_CMD -e $BOSH_ALIAS -n upload-release $POSTGRES_RELEASE_URL
fi

HTTP_PROXY_OPS_FILES=" "
HTTP_PROXY_VARS=" "
if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  HTTP_PROXY_OPS_FILES=" -o $__BASEDIR__/concourse-deployment/cluster/operations/http-proxy.yml "
  HTTP_PROXY_VARS=" -v proxy_url=$HTTP_PROXY \
    -v no_proxy=[$NO_PROXY] "
fi

#### CONCOURSE DEPLOYMENT START #####
$BOSH_CMD -e $BOSH_ALIAS -n deploy $__BASEDIR__/concourse-deployment/cluster/concourse.yml \
  -d concourse \
  $CONCOURSE_VERSIONS_TO_DEPLOY \
  -o $__BASEDIR__/ops-files/nws-azs.yml \
  -o $__BASEDIR__/concourse-deployment/cluster/operations/scale.yml \
  -o $__BASEDIR__/concourse-deployment/cluster/operations/basic-auth.yml \
  -o $__BASEDIR__/concourse-deployment/cluster/operations/tls.yml \
  -o $__BASEDIR__/ops-files/add-tls-vars.yml \
  --vars-store=$__BASEDIR__/$BOSH_ALIAS/concourse-vars.yml \
  -v atc_basic_auth.username=$CONCOURSE_ADMIN_USERNAME \
  -v atc_basic_auth.password=$CONCOURSE_ADMIN_PASSWORD \
  -v tls_bind_port=$TLS_BIND_PORT \
  -v deployment_name=concourse \
  -v az_name=$CONCOURSE_AZ_NAME \
  -v network_name=$CONCOURSE_NW_NAME \
  -v web_network_name=$CONCOURSE_NW_NAME \
  -v web_static_ips=$CONCOURSE_WEB_STATIC_IPS \
  -v concourse_db_ip=$CONCOURSE_DB_STATIC_IPS \
  -v worker_static_ips=$CONCOURSE_WORKER_STATIC_IPS \
  -v concourse_fqdn=$CONCOURSE_FQDN \
  -v external_url=$CONCOURSE_EXTERNAL_URL \
  -v web_instances=$ATC_WEB_INSTANCES \
  -v web_vm_type=$ATC_WEB_VM_TYPE \
  -v db_instances=$CONCOURSE_DB_INSTANCES \
  -v db_vm_type=$CONCOURSE_DB_VM_TYPE \
  -v db_persistent_disk_type=$CONCOURSE_DB_PERSISTENT_DISK_TYPE \
  -v worker_instances=$CONCOURSE_WORKER_INSTANCES \
  -v worker_vm_type=$CONCOURSE_WORKER_VM_TYPE \
  -v skip_ssl_validation=true \
  $CONCOURSE_DEPLOYMENT_OPS_FILES $CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS \
  $HTTP_PROXY_OPS_FILES $HTTP_PROXY_VARS

##### CONCOURSE DEPLOYMENT END #####

$BOSH_CMD -e $BOSH_ALIAS clean-up --all -n
