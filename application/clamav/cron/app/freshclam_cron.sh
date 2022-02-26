#!/usr/bin/with-contenv bash
source /app/_functions.sh

LOCK_FILE="${LOCK_DIR}/${HOST_ID}-freshclam.active"

#### Logic

# Exit if previous execution is still running
if _lock "$$" "${LOCK_FILE}"; then
	# Valid lock detected, previous run must still be executing. Exit gracefully
	exit 0
fi

/usr/bin/freshclam --foreground --config-file="/etc/clamav/freshclam.conf"

# Clean up the PID file so this can run again on next execution
rm "${LOCK_FILE}"
