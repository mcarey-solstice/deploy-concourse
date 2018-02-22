#!/bin/bash -e

if [[ "$FOUNDATION" != "" ]]; then
  echo "sourcing $PWD/scripts/$FOUNDATION-env...."
  source $PWD/scripts/$FOUNDATION-env
else
  echo "sourcing $PWD/env...."
  source $PWD/scripts/env
fi

mkdir -p $BOSH_ALIAS

if [ ! -d "$PWD/bosh-deployment" ]; then
  git clone https://github.com/cloudfoundry/bosh-deployment
else
  cd $PWD/bosh-deployment && git pull && cd ..
fi

HTTP_PROXY_OPS_FILES=" "
HTTP_PROXY_VARS=" "
if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  HTTP_PROXY_OPS_FILES=" -o bosh-deployment/misc/proxy.yml "
  HTTP_PROXY_VARS=" -v http_proxy=$HTTP_PROXY \
        -v https_proxy=$HTTPS_PROXY \
        -v no_proxy=$NO_PROXY "
fi

$BOSH_CMD create-env $PWD/bosh-deployment/bosh.yml \
  --state=$PWD/$BOSH_ALIAS/state.json \
  --vars-store=$PWD/$BOSH_ALIAS/creds.yml \
  -o $PWD/bosh-deployment/vsphere/cpi.yml \
  -o $PWD/bosh-deployment/vsphere/resource-pool.yml \
  -o $PWD/bosh-deployment/jumpbox-user.yml \
  -o $PWD/bosh-deployment/uaa.yml \
  -o $PWD/ops-files/versions.yml \
  -o $PWD/ops-files/dns.yml \
  -v director_name=$BOSH_ALIAS \
  -v internal_cidr=$NETWORK_CIDR \
  -v internal_gw=$NETWORK_GATEWAY \
  -v internal_ip=$BOSH_IP \
  -v dns_servers=$DNS_SERVERS \
  -v network_name="$VCENTER_NETWORK_NAME" \
  -v vcenter_dc="$VSPHERE_DATACENTER" \
  -v vcenter_ds="$VCENTER_STORAGE_NAME" \
  -v vcenter_ip=$VCENTER_IP \
  -v vcenter_user=$VCENTER_USERNAME \
  -v vcenter_password="$VCENTER_PASSWORD" \
  -v vcenter_templates="$VCENTER_VM_TEMPLATES_FOLDER_NAME" \
  -v vcenter_vms="$VCENTER_VMS_FOLDER_NAME" \
  -v vcenter_disks="$VCENTER_DISK_FOLDER_NAME" \
  -v vcenter_cluster="$VCENTER_CLUSTER_NAME" \
  -v vcenter_rp="$VCENTER_RESOURCE_POOL" \
  -v bosh_release_url=$BOSH_RELEASE_URL \
  -v bosh_release_sha=$BOSH_RELEASE_SHA \
  -v vsphere_cpi_release_url=$VSPHERE_CPI_URL \
  -v vsphere_cpi_release_sha=$VSPHERE_CPI_SHA \
  -v stemcell_url=$STEMCELL_URL \
  -v stemcell_sha=$STEMCELL_SHA \
  -v os_conf_release_url=$OS_CONF_RELEASE_URL \
  -v os_conf_release_sha=$OS_CONF_RELEASE_SHA \
  -v uaa_release_url=$UAA_RELEASE_URL \
  -v uaa_release_sha=$UAA_RELEASE_SHA \
  $HTTP_PROXY_OPS_FILES $HTTP_PROXY_VARS

source $PWD/scripts/bosh-login.sh

$BOSH_CMD -e $BOSH_ALIAS -n update-cloud-config $PWD/cloud-configs/cloud-config.yml \
  -v az_name=$CONCOURSE_AZ_NAME \
  -v nw_name=$CONCOURSE_NW_NAME \
  -v vcenter_cluster="$VCENTER_CLUSTER_NAME" \
  -v network_cidr=$NETWORK_CIDR \
  -v network_name="$VCENTER_NETWORK_NAME" \
  -v network_gateway=$NETWORK_GATEWAY \
  -v dns_servers=$DNS_SERVERS \
  -v reserved_ips=$RESERVED_IPS \
  -v static_ips=$CLOUD_CONFIG_STATIC_IPS \
  -v vcenter_rp="$VCENTER_RESOURCE_POOL"

if [ ! -d "$PWD/concourse-deployment" ]; then
  git clone https://github.com/concourse/concourse-deployment
else
  cd $PWD/bosh-deployment && git pull && cd ..
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
  source $PWD/scripts/deploy_credhub.sh

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $PWD/credhub/add-credhub.yml \
        -o $PWD/ops-files/credhub-tls-cert-verify.yml"

  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v insecure_skip_verify=$INSECURE_SKIP_VERIFY"

elif [[ "$CREDENTIAL_MANAGER" == "vault" ]]; then
  echo "Credential manager selected is vault"
  source $PWD/scripts/deploy_vault.sh

  CLIENT_TOKEN=$(cat $PWD/$BOSH_ALIAS/create_token_response.json | $JQ_CMD .auth.client_token | tr -d '"')

  CONCOURSE_DEPLOYMENT_OPS_FILES="-o $PWD/vault/add-vault.yml \
        -o $PWD/ops-files/vault-tls-cert-verify.yml"
  CONCOURSE_DEPLOYMENT_ADDITIONAL_VARS="-v VAULT_ADDR=$VAULT_ADDR \
      -v CLIENT_TOKEN=$CLIENT_TOKEN \
      -v CONCOURSE_VAULT_MOUNT=$CONCOURSE_VAULT_MOUNT \
      -v insecure_skip_verify=$INSECURE_SKIP_VERIFY"
  # -v BACKEND_ROLE=$BACKEND_ROLE \
  # -v ROLE_ID=$ROLE_ID \
  # -v SECRET_ID=$SECRET_ID
else
  echo "Skipping integration with any credential manager"
fi

CONCOURSE_VERSIONS_TO_DEPLOY="-o $PWD/ops-files/concourse-versions.yml"
if [[ "$CONCOURSE_RELEASES_LATEST" == "false" ]]; then
  CONCOURSE_VERSIONS_TO_DEPLOY="-o $PWD/concourse-deployment/versions.yml"
fi

HTTP_PROXY_OPS_FILES=" "
HTTP_PROXY_VARS=" "
if [[ "$HTTP_PROXY_REQUIRED" == "true" ]]; then
  HTTP_PROXY_OPS_FILES=" -o concourse-deployment/cluster/operations/http-proxy.yml "
  HTTP_PROXY_VARS=" -v proxy_url=$HTTP_PROXY \
    -v no_proxy=[$NO_PROXY] "
fi

#### CONCOURSE DEPLOYMENT START #####

$BOSH_CMD -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/concourse/concourse?v=3.8.0

$BOSH_CMD -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release

$BOSH_CMD -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/cloudfoundry/postgres-release

$BOSH_CMD -e $BOSH_ALIAS -n deploy $PWD/concourse-deployment/cluster/concourse.yml \
  -d concourse \
  $CONCOURSE_VERSIONS_TO_DEPLOY \
  -o $PWD/ops-files/nws-azs.yml \
  -o $PWD/concourse-deployment/cluster/operations/scale.yml \
  -o $PWD/concourse-deployment/cluster/operations/basic-auth.yml \
  -o $PWD/concourse-deployment/cluster/operations/tls.yml \
  -o $PWD/ops-files/add-tls-vars.yml \
  --vars-store=$PWD/$BOSH_ALIAS/concourse-vars.yml \
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
