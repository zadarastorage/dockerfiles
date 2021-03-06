#!/bin/ash
# TODO: Support configurable cron schedules, for now every 10 minutes
if [ -n "${CRON_DIR}" -a -d "${CRON_DIR}" ]; then
	echo "*/5	*	*	*	*	/scripts/autoexpand.sh" > "${CRON_DIR}/autoexpand"
else
#	echo "*/10	*	*	*	*	/scripts/autoexpand.sh" > "/var/spool/cron/crontabs/expand"
	if [ ! -d /etc/periodic/5min ]; then
		mkdir /etc/periodic/5min
	fi
	if ! grep -q '/etc/periodic/5min' /var/spool/cron/crontabs/root; then
		echo "*/5	*	*	*	*	run-parts /etc/periodic/5min" >> /var/spool/cron/crontabs/root
	fi
	ln -s /scripts/autoexpand.sh /etc/periodic/5min/autoexpand
fi
