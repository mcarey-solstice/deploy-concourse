#!/bin/bash -ex
source ./env

bosh2 create-env vsphere/bosh.yml \
  --state=vsphere/$BOSH_ALIAS-state.json \
  --vars-store=vsphere/$BOSH_ALIAS-creds.yml \
  -o vsphere/cpi.yml \
  -o vsphere/resource-pool.yml \
  -v director_name=$BOSH_ALIAS \
  -v internal_cidr=$NETWORK_CIDR \
  -v internal_gw=$NETWORK_GATEWAY \
  -v internal_ip=$BOSH_IP \
  -v dns_servers=$DNS_SERVERS \
  -v network_name="$VCENTER_NETWORK_NAME" \
  -v vcenter_dc=$VSPHERE_DATACENTER \
  -v vcenter_ds=$VCENTER_STORAGE_NAME \
  -v vcenter_ip=$VCENTER_IP \
  -v vcenter_user=$VCENTER_USERNAME \
  -v vcenter_password=$VCENTER_PASSWORD \
  -v vcenter_templates=$VCENTER_VM_TEMPLATES_FOLDER_NAME \
  -v vcenter_vms=$VCENTER_VMS_FOLDER_NAME \
  -v vcenter_disks=$VCENTER_DISK_FOLDER_NAME \
  -v vcenter_cluster=$VCENTER_CLUSTER_NAME \
  -v vcenter_rp=$VCENTER_RESOURCE_POOL \
  -v bosh_release_url=$BOSH_RELEASE_URL \
  -v bosh_release_sha=$BOSH_RELEASE_SHA \
  -v vsphere_cpi_url=$VSPHERE_CPI_URL \
  -v vsphere_cpi_sha=$VSPHERE_CPI_SHA \
  -v stemcell_url=$STEMCELL_URL \
  -v stemcell_sha=$STEMCELL_SHA

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh2 int ./vsphere/$BOSH_ALIAS-creds.yml --path /admin_password`

bosh2 -e $BOSH_IP --ca-cert <(bosh2 int ./vsphere/$BOSH_ALIAS-creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS

bosh2 -e $BOSH_ALIAS -n update-cloud-config vsphere/cloud-config.yml \
  -v concourse_az_name=$CONCOURSE_AZ_NAME \
  -v concourse_nw_name=$CONCOURSE_NW_NAME \
  -v vcenter_cluster=$VCENTER_CLUSTER_NAME \
  -v network_cidr=$NETWORK_CIDR \
  -v network_name=$VCENTER_NETWORK_NAME \
  -v network_gateway=$NETWORK_GATEWAY \
  -v dns_servers=$DNS_SERVERS \
  -v reserved_ips=$RESERVED_IPS \
  -v static_ips_1=$CONCOURSE_STATIC_IP \
  -v static_ips_2=$VAULT_STATIC_IP \
  -v static_ips_3=$NEXUS_STATIC_IP \
  -v vcenter_rp=$VCENTER_RESOURCE_POOL

bosh2 -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/concourse/concourse

bosh2 -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release

bosh2 -e $BOSH_ALIAS -n upload-release https://github.com/making/nexus-boshrelease/releases/download/${NEXUS_VERSION}/nexus-${NEXUS_VERSION}.tgz

bosh2 -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease

bosh2 -e $BOSH_ALIAS -n upload-release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease

if [[ ! -f "bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz" ]]; then
  wget --show-progress https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz
fi

bosh2 -e $BOSH_ALIAS -n upload-stemcell bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz

##### VAULT DEPLOYMENT START #####
bosh2 -e $BOSH_ALIAS -n -d vault deploy vault.yml \
  -v VAULT_AZ_NAME=$VAULT_AZ_NAME \
  -v VAULT_NW_NAME=$VAULT_NW_NAME \
  -v VAULT_STATIC_IP=$VAULT_STATIC_IP \
  -v VAULT_INSTANCES=$VAULT_INSTANCES \
  -v VAULT_VM_TYPE=$VAULT_VM_TYPE
##### VAULT DEPLOYMENT END #####

##### VAULT CONFIGURATION START #####
# Initialize vault

set +e
IS_VAULT_INTIALIZED=$(curl -m 10 -s -o /dev/null -w "%{http_code}" $VAULT_ADDR/v1/sys/health)
set -e

if [ $IS_VAULT_INTIALIZED -ne 200 ]; then
  echo "Initalizing Vault"
  VAULT_INIT_RESPONSE=$(vault init)

  rm -rf vault.log

  echo "$VAULT_INIT_RESPONSE" >> vault.log

  # Unseal the vault
  set +x
  export VAULT_TOKEN=$(cat vault.log | grep 'Initial Root Token' | awk '{print $4}')

  vault unseal $(cat vault.log | grep 'Unseal Key 1' | awk '{print $4}')
  vault unseal $(cat vault.log | grep 'Unseal Key 2' | awk '{print $4}')
  vault unseal $(cat vault.log | grep 'Unseal Key 3' | awk '{print $4}')
  set -x

  # Create a mount for concourse
  vault mount -path=$CONCOURSE_VAULT_MOUNT -description="Secrets for use by concourse pipelines" generic

  # Create application policy
  vault policy-write $VAULT_POLICY_NAME vault-policy.hcl
  CREATE_TOKEN_RESPONSE=$(vault token-create --policy=$VAULT_POLICY_NAME -period="87600h" -format=json)
  rm -rf create_token_response.json
  echo $CREATE_TOKEN_RESPONSE >> create_token_response.json
else
  echo "Vault already initialized and hence skipping this step"
fi

### Token based authentication ###
# Create a token with the specified policy

## Approle based authentication ###
# vault auth-enable approle
# vault write auth/approle/role/$ROLE_NAME policies=$VAULT_POLICY_NAME -period="87600h"
# export ROLE_ID=$(vault read -format=json auth/approle/role/$ROLE_NAME/role-id | jq .data.role_id | tr -d '"')
# export SECRET_ID=$(vault write -format=json -f auth/approle/role/$ROLE_NAME/secret-id | jq .data.secret_id | tr -d '"')
# export CLIENT_TOKEN=$(vault write -format=json auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID | jq .auth.client_token | tr -d '"')

#### VAULT CONFIGURATION END #####

CLIENT_TOKEN=$(cat create_token_response.json | jq .auth.client_token | tr -d '"')

#### CONCOURSE DEPLOYMENT START #####
bosh2 -e $BOSH_ALIAS -n -d concourse deploy concourse.yml \
  -v CONCOURSE_AZ_NAME=$CONCOURSE_AZ_NAME \
  -v CONCOURSE_NW_NAME=$CONCOURSE_NW_NAME \
  -v STATIC_IP=$CONCOURSE_STATIC_IP \
  -v CONCOURSE_EXTERNAL_URL=$CONCOURSE_EXTERNAL_URL \
  -v VAULT_ADDR=$VAULT_ADDR \
  -v CLIENT_TOKEN=$CLIENT_TOKEN \
  -v CONCOURSE_VAULT_MOUNT=$CONCOURSE_VAULT_MOUNT \
  -v CONCOURSE_ADMIN_USERNAME=$CONCOURSE_ADMIN_USERNAME \
  -v CONCOURSE_ADMIN_PASSWORD=$CONCOURSE_ADMIN_PASSWORD
  # -v BACKEND_ROLE=$BACKEND_ROLE \
  # -v ROLE_ID=$ROLE_ID \
  # -v SECRET_ID=$SECRET_ID
##### CONCOURSE DEPLOYMENT END #####

bosh2 -e $BOSH_ALIAS -n -d nexus deploy nexus.yml \
  -v NEXUS_AZ_NAME=$NEXUS_AZ_NAME \
  -v NEXUS_NW_NAME=$NEXUS_NW_NAME \
  -v NEXUS_INSTANCES=$NEXUS_INSTANCES \
  -v NEXUS_VM_TYPE=$NEXUS_VM_TYPE \
  -v STATIC_IP=$NEXUS_STATIC_IP

bosh2 -e $BOSH_ALIAS clean-up --all -n
