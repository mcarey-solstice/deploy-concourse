#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../load-env
source "$__DIR__"/../releases bosh uaa stemcell vsphere_cpi os_conf

BOSH_DEPLOYMENT_DIRECTORY="$VENDOR_DIRECTORY/bosh-deployment"

# TODO - Check that all bosh deployments are deleted before allowing delete

$BOSH_CMD -e "$BOSH_ALIAS" clean-up --all -n

$BOSH_CMD \
  delete-env "$BOSH_DEPLOYMENT_DIRECTORY"/bosh.yml \
    --state="$OUTPUT_DIRECTORY"/state.json \
    --vars-store="$OUTPUT_DIRECTORY"/creds.yml \
    -o "$BOSH_DEPLOYMENT_DIRECTORY"/vsphere/cpi.yml \
    -o "$BOSH_DEPLOYMENT_DIRECTORY"/vsphere/resource-pool.yml \
    -o "$BOSH_DEPLOYMENT_DIRECTORY"/jumpbox-user.yml \
    -o "$BOSH_DEPLOYMENT_DIRECTORY"/uaa.yml \
    -o "$__BASEDIR__"/ops-files/versions.yml \
    -o "$__BASEDIR__"/ops-files/dns.yml \
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
    -v uaa_release_sha="$UAA_RELEASE_SHA"

rm -rf "$BOSH_DEPLOYMENT_DIRECTORY"

# deletes bosh
