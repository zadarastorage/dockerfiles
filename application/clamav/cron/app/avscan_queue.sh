#!/usr/bin/with-contenv bash
source /app/_functions.sh
LOCK_FILE="${LOCK_DIR}/${HOST_ID}-scan.active"

# Exit if previous execution is still running
if _lock "$$" "${LOCK_FILE}"; then
	# Valid lock detected
	exit 0
fi

# LOG_PATH is required 
if [[ -z "${LOG_PATH}" ]]; then
	_error "LOG_PATH was undefined, not sure where to store logs."
	exit 1
fi

# Ensure clamd service is up and socket exists, incase service has crashed or is still starting up
for x in {1..10}; do
	if [[ ! -S "/var/run/clamav/clamd.ctl" ]]; then
		 sleep 5s
	else
		 break
	fi
done
if [[ ! -S "/var/run/clamav/clamd.ctl" ]]; then
	_log "[$$] Clamd service wasn't ready. No files were scanned on this attempt."
	exit 0
fi

#### Processing logic
_log "[$$] AV Scan of manifest entries starting"
MANIFEST_LIST=( $(find "${QUEUE_DIR}/" -mindepth 1 -maxdepth 1 -type f -mmin +2 -iname '*.manifest' -printf '%T@ %P\n' | sort -n 2>/dev/null | head -n 10 | cut -d ' ' -f2-) )
COUNT=${#MANIFEST_LIST[@]}
while [[ ${#MANIFEST_LIST[@]} -gt 0 ]]; do
	# Process each manifest
	for MANIFEST in ${MANIFEST_LIST[@]}; do
		if [[ ! -S "/var/run/clamav/clamd.ctl" ]]; then
			break 2
		fi
		scanQueue "$$" "${QUEUE_DIR}/${MANIFEST}"
	done
	# Refresh MANIFEST_LIST
	MANIFEST_LIST=( $(find "${QUEUE_DIR}/" -mindepth 1 -maxdepth 1 -type f -mmin +2 -iname '*.manifest' -printf '%T@ %P\n' | sort -n 2>/dev/null | head -n 10 | cut -d ' ' -f2-) )
	COUNT=$(( ${COUNT} + ${#MANIFEST_LIST[@]} ))
done
_log "[$$] AV Scan of manifest entries ended. ${COUNT} manifests were processed."

# Clean up the PID file so this can run again on next execution
rm "${LOCK_FILE}"
