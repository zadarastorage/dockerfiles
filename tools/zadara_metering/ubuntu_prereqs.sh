#!/bin/bash
DOCKER=17.03.1~ce-0~ubuntu-$(lsb_release -cs)
COMPOSE=1.12.0

if [[ $EUID -ne 0 ]]; then
	echo "This needs to run as root/sudo"
else
	# Install docker-ce
	apt-get -y install apt-transport-https ca-certificates curl
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	apt-get -y update
	apt-get -y install docker-ce=${DOCKER}

	# Install docker-compose
	curl -L https://github.com/docker/compose/releases/download/${COMPOSE}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose

	# Install any other packages
	apt-get -y install zip unzip curl
fi
