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

- Create a copy of the template `env-template` file and name it as `dev-env` or `[ENV]-env`
-	Fill out the `[ENV]-env` file
- Specify the credential manager you want to use with your concourse deployment
-	Use blocks of IP's for all the static_ips in the `[ENV]-env` file, ex: 192.168.0.10-192.16.0.12
-	To deploy, execute `ENV=dev ./scripts/deploy.sh`, where `dev` is the name of the foundation
-	To wipe the environment, execute `ENV=dev ./scripts/delete.sh`

Limitations:
------------

- All configuration is currently for vSphere. Should be easy to swap them out to support the IaaS you need
-	Currently doesn't allow setting multiple DNS Servers and since static IP's for all the components accessible by developers
-	Hasn't enabled ssh access to bosh
-	Tested on OSX/Linux :)

Caution:
--------

-	Make sure the network has internet connectivity, else download the releases and push them to bosh director
-	Backup the `$BOSH-ALIAS` folder, loosing it will make your life miserable :-)
-	Do not delete the vault.log and create_token_response.json generated under `$BOSH-ALIAS` folder
-	Loosing the above will make vault and/or concourse unusable and you have to redeploy concourse
-	Supports single DNS Server

Mirroring the respoitory:
-------------------------

Out of the box, the scripts will look inside the `scripts` directory for the env files and `$BOSH-ALIAS` directory will store the creds and output files for an environment.  One can move where these files are stored and therefore keep the logic separate from the storage files thus allowing the logic up-to-date and the storage to your backups or a separate repository.

- Set the `ENV_DIRECTORY` environment variable globally to change where the env scripts are loaded from.
- Set the `OUTPUT_DIRECTORY` environment variable globally to change where the `$BOSH-ALIAS` directories are stored.
