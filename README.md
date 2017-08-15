HOW TO USE
----------

Download the following CLI's:
-----------------------------

-	Vault cli
-	Bosh2 cli
-	jq

Usage:
------

-	Fill out the `env` file
-	Use blocks of IP's for all the static_ips in the `env` file, ex: 192.168.0.10-192.16.0.12
-	To deploy, execute `deploy.sh`
-	To wipe the environment, execute `delete.sh`

Limitations:
------------

-	Currently doesn't allow setting multiple DNS Servers and since static IP's for all the components accessible by developers
-	Hasn't enabled ssh access to bosh
-	Tested on Mac :)

Caution:
--------

-	Make sure the network has internet connectivity, else download the releases and push them to bosh director
-	Do not delete the vault.log and create_token_response.json
-	Loosing the above will make vault and/or concourse unusable and you have to redeploy concourse
-	Backup the `vsphere/$BOSH-ALIAS.json` and `vsphere/$BOSH-ALIAS-creds.yml`
-	Supports single DNS
