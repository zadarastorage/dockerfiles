#!/bin/bash
DOCKER=18.03.0~ce-0~ubuntu
COMPOSE=1.18.0

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
	apt-get -y install docker-compose
	apt-get -y install python-docker

	# Install any other packages
	apt-get -y install zip unzip curl telnet moreutils
fi
