HOW TO USE
----------

This script needs to be updated to support multiple instances of concourse `web` and `vault` and `nexus`

Download the following CLI's:
-----------------------------

-	Vault cli
-	Bosh2 cli
-	jq

Usage:
------

-	Fill out the `env` file
-	To deploy, execute `deploy.sh`
-	To wipe the environment, execute `delete.sh`

Limitations:
------------

-	Currently doesn't allow setting multiple DNS Servers and since static IP's for all the components accessible by developers
-	Hasn't enabled ssh access to bosh
-	Tested on Mac :)
