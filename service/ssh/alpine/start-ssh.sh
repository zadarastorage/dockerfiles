#!/bin/sh
if [ "${SSH_SERVER}" == "enabled" ]; then
	if [ -n "${SSH_USER}" ] && [ -n "${SSH_PASSWORD}" ]; then
		if [ "${SSH_USER}" != "root" ]; then
			adduser "${SSH_USER}"
		fi
		echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd
	fi
	/usr/sbin/sshd -D
else
	while :; do
		sleep 60m
	done
fi
