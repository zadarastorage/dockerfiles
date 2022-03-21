#!/usr/bin/with-contenv bash
source /app/_functions.sh
LOCK_FILE="${LOCK_DIR}/${HOST_ID}-find.active"

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
if [[ ! -d "${LOG_PATH}" ]]; then
        _error "LOG_PATH[${LOG_PATH}] was not a directory, exiting."
        exit 1
fi

FIND_FOLDERS=( $(getMounts | grep -v -e "^${LOG_PATH}$" -e "^${QUAR_PATH:-}$") )
if [[ ${#FIND_FOLDERS[@]} -eq 0 ]]; then
	_error "No folders detected as attached to this docker container. Not scanning for modified files."
	exit 1
fi

#### Processing logic
## Re-queue incomplete manifests
_log "[$$] Re-queue orphan manifests starting"
requeueOrphanManifests "$$"
_log "[$$] Re-queue orphan manifests ended"

## Generate new manifest
_log "[$$] Search for new or modified files starting"
getMounts | grep -v -e "^${LOG_PATH}$" -e "^${QUAR_PATH:-}$" | env_parallel -n 1 -P ${FIND_THREADS:-1} -I {} findFiles "$$" {}
_log "[$$] Search for new or modified files ended"

# Clean up the PID file so this can run again on next execution
rm "${LOCK_FILE}"
