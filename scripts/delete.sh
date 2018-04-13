#!/bin/bash -e

__DIR__=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
__BASEDIR__=$(dirname $__DIR__)

source $__DIR__/load-env.sh
source $__DIR__/releases

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$BOSH_CMD int $__BASEDIR__/$BOSH_ALIAS/creds.yml --path /admin_password`
$BOSH_CMD -e $BOSH_IP --ca-cert <($BOSH_CMD int $__BASEDIR__/$BOSH_ALIAS/creds.yml --path /director_ssl/ca) alias-env $BOSH_ALIAS

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d nexus -n --force

$BOSH_CMD delete-deployment -e $BOSH_ALIAS -d concourse -n --force

if [[ "$CREDENTIAL_MANAGER" == "vault" ]]; then
  $BOSH_CMD delete-deployment -e $BOSH_ALIAS -d vault -n --force
else
  echo "Skipping integration with any credential manager"
fi

$BOSH_CMD -e $BOSH_ALIAS clean-up --all -n

$BOSH_CMD delete-env $__BASEDIR__/bosh-deployment/bosh.yml \
  --state=$__BASEDIR__/$BOSH_ALIAS/state.json \
  --vars-store=$__BASEDIR__/$BOSH_ALIAS/creds.yml \
  -o $__BASEDIR__/bosh-deployment/vsphere/cpi.yml \
  -o $__BASEDIR__/bosh-deployment/vsphere/resource-pool.yml \
  -o $__BASEDIR__/bosh-deployment/jumpbox-user.yml \
  -o $__BASEDIR__/bosh-deployment/uaa.yml \
  -o $__BASEDIR__/ops-files/versions.yml \
  -o $__BASEDIR__/ops-files/dns.yml \
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

rm -rf $__BASEDIR__/$BOSH_ALIAS

if [[ ! -f "bosh-stemcell-$SC_VERSION-vsphere-esxi-ubuntu-trusty-go_agent.tgz" ]]; then
  rm -f bosh-stemcell-*.tgz
fi
