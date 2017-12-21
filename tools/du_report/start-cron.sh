#!/bin/sh

> /var/log/run.log

if [ -n "${CRON_STRING}" ]
then
    echo "${CRON_STRING} sh /app/start-du.sh" >> /etc/crontabs/root
else
    echo "0 0 * * * sh /app/start-du.sh" >> /etc/crontabs/root
fi

crond && tail -f /var/log/run.log