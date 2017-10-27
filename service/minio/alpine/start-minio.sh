#!/bin/sh
if [ "${MINIO_SERVER}" == "enabled" ]; then
	if [ "${MINIO_REGION}" == "zadara_vpsa"] && [ "${VPSA_ACCESS_KEY}" != "" ]; then
		# TODO: Lookup VPSA name and update the region accordingly
		VPSA_IP=$( ip route|awk '/default/ { print $3 }' )
		VPSA_DISPLAY_NAME=$(curl -s -k -X GET "https://${VPSA_IP}/" | grep 'VsaGui.vpsaName' | sed "s#.*\"\(.*\)\".*#\1#g")
		export MINIO_REGION=${VPSA_DISPLAY_NAME}
	fi
	/app/minio --quiet server --config-dir "${MINIO_CONF_DIR}" "${MINIO_DATA_DIR}" &>> /dev/null
fi
