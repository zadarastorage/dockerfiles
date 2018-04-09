#!/bin/sh
if [ "${CRON_SERVICE}" == "enabled" ]; then
	if [ -n "${CRON_DIR}" ] && [ -d "${CRON_DIR}" ]; then
		/usr/sbin/crond -f -C "${CRON_DIR}"
	else
		/usr/sbin/crond -f
	fi
else
	while :; do
		sleep 60m
	done
fi
