#!/bin/ash
# TODO: Support configurable cron schedules, for now every 10 minutes
if [ -n "${CRON_DIR}" -a -d "${CRON_DIR}" ]; then
	echo "*/10	*	*	*	*	/scripts/autoexpand.sh" > "${CRON_DIR}/autoexpand"
else
#	echo "*/10	*	*	*	*	/scripts/autoexpand.sh" > "/var/spool/cron/crontabs/expand"
	ln -s /scripts/autoexpand.sh /etc/periodic/15min/autoexpand
fi
