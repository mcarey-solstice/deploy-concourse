#!/bin/bash -e

declare -r __DIR__="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

source "$__DIR__"/../helpers
source "$__DIR__"/../load-env

RESOURCE_POOL_OPS_FILE=" "
RESOURCE_POOL_VARS=" "
if [ -n "$VCENTER_RESOURCE_POOL" ]; then
  RESOURCE_POOL_OPS_FILE=" -o $__BASE_DIR__/ops-files/add-vcenter-resource-pool.yml"
  RESOURCE_POOL_VARS=" -v vcenter_rp=\"$VCENTER_RESOURCE_POOL\""
fi

CLOUD_CONFIG="$__BASEDIR__"/cloud-configs/cloud-config.yml
if [ -z "$CUSTOM_CLOUD_CONFIG" ]; then
    CLOUD_CONFIG="$CUSTOM_CLOUD_CONFIG"
fi

log "Updating the bosh cloud config"
$BOSH_CMD -n \
  -e "$BOSH_ALIAS" \
  update-cloud-config "$CLOUD_CONFIG" \
    -v az_name="$CONCOURSE_AZ_NAME" \
    -v nw_name="$CONCOURSE_NW_NAME" \
    -v vcenter_cluster="$VCENTER_CLUSTER_NAME" \
    -v network_cidr="$NETWORK_CIDR" \
    -v network_name="$VCENTER_NETWORK_NAME" \
    -v network_gateway="$NETWORK_GATEWAY" \
    -v dns_servers="[$DNS_SERVERS]" \
    -v reserved_ips="$RESERVED_IPS" \
    -v static_ips="$CLOUD_CONFIG_STATIC_IPS" \
    -v vm_disk_type="$VM_DISK_TYPE" \
    $RESOURCE_POOL_OPS_FILE $RESOURCE_POOL_VARS

# uploads bosh cloud-config
