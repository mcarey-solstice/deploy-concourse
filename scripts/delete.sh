#!/bin/bash -e

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/load-env.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/releases

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /admin_password`
$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $PWD/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d nexus -n --force

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d concourse -n --force

if [[ "$CREDENTIAL_MANAGER" == "vault" ]]; then
  $BOSH_CMD delete-deployment -e $BOSH_ALIAS -d vault -n --force
else
  echo "Skipping integration with any credential manager"
fi

$BOSH_CMD -e $BOSH_ALIAS clean-up --all -n

$BOSH_CMD delete-env $PWD/bosh-deployment/bosh.yml \
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
  -v vsphere_cpi_release_url=$VSPHERE_CPI_URL \
  -v vsphere_cpi_release_sha=$VSPHERE_CPI_SHA \
  -v stemcell_url=$STEMCELL_URL \
  -v stemcell_sha=$STEMCELL_SHA \
  -v os_conf_release_url=$OS_CONF_RELEASE_URL \
  -v os_conf_release_sha=$OS_CONF_RELEASE_SHA \
  -v uaa_release_url=$UAA_RELEASE_URL \
  -v uaa_release_sha=$UAA_RELEASE_SHA

rm -rf $PWD/$BOSH_ALIAS

if [[ ! -f "bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz" ]]; then
  rm -f bosh-stemcell-*.tgz
fi
