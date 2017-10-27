#!/usr/bin/env bash
printenv | sed -e 's/^\(.*\)$/export \1"/g' -e 's/=/="/' > /env.sh
chmod +x /env.sh

echo -n "" > /etc/cron.d/scan_cron

if [[ -x "./ssh_server.sh" && "${ENABLE_SSH}" != "" ]]; then
	./ssh_server.sh &
fi

if [[ -x "./clamav_daemon.sh" && ("${MODE}" == "" || "${MODE}" == "av") ]]; then
	ARBITRARY_OFFSET=$(( $(date +%s%N) % 60 ))
	if [[ "${DEF_UPD_FREQ}" == "" ]]; then
		DEF_UPD_FREQ=24
	fi
	HOUR_OFF=$(expr 24 / ${DEF_UPD_FREQ})
	REFERENCE="${ARBITRARY_OFFSET} */${HOUR_OFF} * * * root /etc/init.d/clamav-freshclam no-daemon 2>&1" # ARBITRARY MINUTE every HOUR
        echo "${REFERENCE}"
        echo "${REFERENCE}" >> /etc/cron.d/scan_cron
        ./clamav_daemon.sh &
fi

if [[ -x "./queue_process.sh" && ("${MODE}" == "" || "${MODE}" == "av") ]]; then
	if [[ "${AV_CRON}" == "" ]]; then
		ARBITRARY_OFFSET=$(( $(date +%s%N) % 60 ))
		AV_CRON="${ARBITRARY_OFFSET} * * * *"
	fi
	REFERENCE="${AV_CRON} root . /env.sh; bash /queue_process.sh >> ${LOG_PATH}/queue_process.log 2>&1" # ARBITRARY MINUTE every HOUR
	echo "${REFERENCE}"
	echo "${REFERENCE}" >> /etc/cron.d/scan_cron
fi

if [[ -x "./find_changes.sh" && ("${MODE}" == "" || "${MODE}" == "find") ]]; then
	if [[ "${FIND_CRON}" == "" ]]; then
		ARBITRARY_OFFSET=$(( $(date +%s%N) % 60 ))
		FIND_CRON="${ARBITRARY_OFFSET} * * * *"
	fi
	REFERENCE="${FIND_CRON} root . /env.sh; bash /find_changes.sh >> ${LOG_PATH}/finddata.log 2>&1" # ARBITRARY MINUTE every HOUR
	echo "${REFERENCE}"
	echo "${REFERENCE}" >> /etc/cron.d/scan_cron
fi

cat << EOF > /etc/logrotate.d/zad_clam
${LOG_PATH}/clamav-clamd.log
${LOG_PATH}/clamav-freshclamd.log
${LOG_PATH}/finddata.log
${LOG_PATH}/queue_process.log
{
	rotate 7
	daily
	missingok
	notifempty
	delaycompress
	compress
	postrotate
	size 1024k
	create 644 root root
}
EOF

if [[ -x "/etc/cron.d/scan_cron" ]]; then
	echo "" >> /etc/cron.d/scan_cron
	chmod 0644 /etc/cron.d/scan_cron
fi
touch ${LOG_PATH}/finddata.log ${LOG_PATH}/queue_process.log

cron && tail -f /var/log/dmesg
