#!/bin/sh
if [ "${MINIO_SERVER}" == "enabled" ]; then
	if [ "${MINIO_REGION}" == "zadara_vpsa"] && [ "${VPSA_ACCESS_KEY}" != "" ]; then
		# TODO: Lookup VPSA name and update the region accordingly
	fi
	/app/minio --quiet server --config-dir "${MINIO_CONF_DIR}" "${MINIO_DATA_DIR}" &>> /dev/null
fi
