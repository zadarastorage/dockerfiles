#!/usr/bin/env bash
# Daemon
sed -i 's/User clamav/User root/' /etc/clamav/clamd.conf
if [[ "${LOG_PATH}" != "" ]]; then
	sed -i "s@LogFile .*@LogFile ${LOG_PATH}/clamav-clamd.log@" /etc/clamav/clamd.conf
fi

# Freshclam
sed -i 's/DatabaseOwner clamav/DatabaseOwner root/' /etc/clamav/freshclam.conf
if [[ "${PROXY_SERVER}" != "" && "${PROXY_PORT}" != "" ]]; then
	echo "HTTPProxyServer ${PROXY_SERVER}" >> /etc/clamav/freshclam.conf
	echo "HTTPProxyPort ${PROXY_PORT}" >> /etc/clamav/freshclam.conf
fi
if [[ "${DEF_UPD_FREQ}" != "" ]]; then
	sed -i "s/Checks.*/Checks ${DEF_UPD_FREQ}/" /etc/clamav/freshclam.conf
fi
if [[ "${LOG_PATH}" != "" ]]; then
	sed -i "s@LogFile .*@LogFile ${LOG_PATH}/clamav-freshclamd.log@" /etc/clamav/freshclam.conf
fi

service clamav-daemon start
#service clamav-freshclam start
