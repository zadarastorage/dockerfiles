#!/bin/sh

python /app/check_requirements.py

if [ $? != 0 ]; then
    exit 1
fi


if [ "${SSH}" == "enabled" ] || [ "${SSH}" == true ] || [ "${SSH}" == "true" ]; then
    /usr/sbin/sshd -D &
fi


if [ "${CRON}" == "enabled" ] || [ "${CRON}" == true ] || [ "${CRON}" == "true" ]; then
    cat /etc/crontabs/root > /etc/crontabs/zadara
    echo "${CRON_TIMING} python /app/delete.py" >> /etc/crontabs/zadara;
    crontab /etc/crontabs/zadara
    crond
fi


if [ "${STARTUP_RUN}" == "enabled" ] || [ "${STARTUP_RUN}" == true ] || [ "${STARTUP_RUN}" == "true" ]; then
    python /app/delete.py
fi

if [ "${CRON}" == "enabled" ] || [ "${CRON}" == true ] || [ "${CRON}" == "true" ] ||
   [ "${KEEP_ALIVE}" == "enabled" ] || [ "${KEEP_ALIVE}" == true ] ; then
    while :; do
        sleep 60m
    done
fi