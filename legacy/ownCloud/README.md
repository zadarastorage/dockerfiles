# Running ownCloud on YOUR Zadara VPSA
![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ownCloud/assets/ownCloud.jpg)

OwnCloud is an open source app which provides **private** Dropbox-like file sharing, collaboration and cloud storage capabilities. The instructions herein, tell you how to add this capability to your [Zadara Enterprise Storage](https://www.zadarastorage.com) VPSA using Docker.

## Prerequisites 
VPSA Model 400 or higher with ZCS enabled.


Image specific:

- ownCloud 9.0+ latest

## Installation Image

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ownCloud/assets/create-docker-image.jpg)

Latest version of ownCloud is supported. Simply search the Docker public hub and select the version with the "latest" tags.

## VPSA Volume

Create a VPSA volume with at least 1TB of storage. This volume can be thinly provisioned. Use SAS with caching enabled or SSDs for the pool.  You will need to mount this volume to manually change the config file.  Use a Linux instance for this.

## ZCS Container

Create a ZCS container
- Name: Anything You Like
- Image: owncloud
- Container Ports: 80
- Volumes: <the Volume you created> mapped to /var/www/html
- Args: apache2-foreground
- Entry Point/entrypoint.sh
- Start after creation [yes]

The container will take a while to install. Click on the port ranges tab in the Container Details to determine which port is mapped to 80

### Admin Configuration

Use the IP Address of the container or subdomain name of the VPSA. Use a browser to open up the web page. Remember to add :PORT to the URL

- Create an admin user and password
- Select the database (sqllte)

### Post Installation

When you access your ownCloud using the VPSA URL with the :PORT#, ownCloud will not be able to route the URL's properly.

You need to edit the config.php file to remove the port number from the **trusted_domains** variable.  This is going to be the ":9229" as shown below.

```
<?php
$CONFIG = array (
  'instanceid' => 'oc5wjaxw4wi8',
  'passwordsalt' => 'y9NYmx8Lj2aC/dLZ4/wAGrKZkjO+HP',
  'secret' => 'JaIKo/1wBCY5xG+DhojQyWjGmYueMv47aykwkZJX366fARDt',
  'trusted_domains' =>
  array (
    0 => 'vsa-0000000c-aws-jp1.zadaravpsa.com:9229',
  ),
  'datadirectory' => '/var/www/html/data',
  'overwrite.cli.url' => 'http://vsa-0000000c-aws-jp1.zadaravpsa.com:9229',
  'dbtype' => 'sqlite3',
  'version' => '9.0.0.19',
  'logtimezone' => 'UTC',
  'installed' => true,
);
```

Only remove the port number from **trusted_domains** and not for **overwrite.cli.url**.

You will now be able to access ownCloud using your VPSA URL with the port number.

### Adding a Public Interface

A proxy pass through works best if you want to make ownCloud available via a public IP or URL.  The easiest way is to do this is to use [NGINX](http://nginx.org). 

For this example, all you need is a server record for the proxy:

```

server {

location / {
    proxy_pass http://vsa-0000000c-aws-jp1.zadaravpsa.com:9229/;

	}

}

```
