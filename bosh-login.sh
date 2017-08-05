#!/bin/bash

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh2 int ./vsphere/creds.yml --path /admin_password`
