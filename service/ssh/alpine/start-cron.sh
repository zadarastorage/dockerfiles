#!/bin/sh
if [ "${CRON_SERVICE}" == "enabled" ]; then
	/usr/sbin/crond -f
else
	while :; do
		sleep 60m
	done
fi
