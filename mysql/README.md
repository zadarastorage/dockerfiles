# MySQL 

An example configuration of [MySQL](https://www.mysql.com/) running as ZCS.

You would map your VPSA volume as /mnt and a mysql directory and database will be 
created if it does not exist. 

## TODO

* Need to verify port routing when connecting remote
* Need to accept and configure container using environment variables or arguments
* Need to configure MySQL database location using args instead of /mnt/mysql

## ssh

* Has root ssh access to configure the database and add external access
* The passwd is zadara, so please change it afterwards.

