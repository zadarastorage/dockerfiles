#!/usr/bin/env bash
# Daemon
sed -i 's/User clamav/User root/' /etc/clamav/clamd.conf
if [[ "${LOG_PATH}" != "" ]]; then
	sed -i "s@LogFile .*@LogFile ${LOG_PATH}/clamav-clamd.log@" /etc/clamav/clamd.conf
fi
grep -qxF "ConcurrentDatabaseReload no" /etc/clamav/clamd.conf || echo "ConcurrentDatabaseReload no" >> /etc/clamav/clamd.conf

# Freshclam
sed -i 's/DatabaseOwner clamav/DatabaseOwner root/' /etc/clamav/freshclam.conf
sed -i 's/ReceiveTimeout.*/ReceiveTimeout 60/' /etc/clamav/freshclam.conf
sed -i 's/TestDatabases.*/TestDatabases no/' /etc/clamav/freshclam.conf
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

/usr/sbin/clamd --foreground
#service clamav-daemon start
#service clamav-freshclam start
