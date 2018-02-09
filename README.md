HOW TO USE
----------

Download the following CLI's:
-----------------------------

- credhub cli
-	vault cli
-	bosh v2 cli
-	jq

Usage:
------

- Create a copy of the template `env` file and name it as `dev-env` or `[FOUNDATION]-env`
-	Fill out the `[FOUNDATION]-env` file
- Specify the credential manager you want to use with your concourse deployment
-	Use blocks of IP's for all the static_ips in the `[FOUNDATION]-env` file, ex: 192.168.0.10-192.16.0.12
-	To deploy, execute `FOUNDATION=dev ./scripts/deploy.sh`, where `dev` is the name of the foundation
-	To wipe the environment, execute `FOUNDATION=dev ./scripts/delete.sh`

Limitations:
------------

- All configuration is currently for vSphere. Should be easy to swap them out to support the IaaS you need
-	Currently doesn't allow setting multiple DNS Servers and since static IP's for all the components accessible by developers
-	Hasn't enabled ssh access to bosh
-	Tested on Mac :)

Caution:
--------

-	Make sure the network has internet connectivity, else download the releases and push them to bosh director
-	Backup the `$BOSH-ALIAS` folder, loosing it will make your life miserable :-)
-	Do not delete the vault.log and create_token_response.json generated under `$BOSH-ALIAS` folder
-	Loosing the above will make vault and/or concourse unusable and you have to redeploy concourse
-	Supports single DNS Server
