#!/usr/bin/with-contenv bash
source /usr/bin/env_parallel.bash

LOCK_DIR="/dev/shm"
HOST_ID=$(hostname)

QUEUE_DIR="${LOG_PATH}/queue"
STATS_DIR="${LOG_PATH}/stats"
if [[ -d "${LOG_PATH}" && ! -d "${QUEUE_DIR}" ]]; then
	mkdir -p "${QUEUE_DIR}"
fi
if [[ -d "${LOG_PATH}" && ! -d "${STATS_DIR}" ]]; then
	mkdir -p "${STATS_DIR}"
fi

function _log {
	(>&2 echo "$(date -u --rfc-3339=ns) ${0}: ${@}")
}
function _error {
	# TODO: Decide if _error should do anything more elaborate with received message
	_log "${@}"
}

function _lock {
	_PID="${1}"
	LOCK_FILE="${2}"
	if [[ -e "${LOCK_FILE}" ]]; then
		EPID=$(< "${LOCK_FILE}")
		if ! kill -0 ${EPID} &>/dev/null; then
			rm "${LOCK_FILE}"
		fi
	fi
	if [[ -e "${LOCK_FILE}" ]]; then
		return 0
	elif [[ ! -e "${LOCK_FILE}" ]]; then
		echo "${_PID}" > "${LOCK_FILE}"
		return 1
	fi
}

function clamdRunning {
	# Simple check, clamd isn't running if either of these do not exist
	if [[ ! -S "/var/run/clamav/clamd.ctl" || ! -e "/dev/shm/clamd.pid" ]]; then
		return 1
	fi
	# Pidcheck
	if [[ -e "/dev/shm/clamd.pid" ]]; then
		EPID=$(< "${LOCK_FILE}")
		if ! kill -0 ${EPID} &>/dev/null; then
			return 1
		fi
	fi
	return 0
}

# supportTicket "level" "title" "message"
function supportTicket {
	if [[ "${VPSA_ACCESSKEY}" != "" ]]; then
		PAYLOAD="{}"
		LVL=$(echo "$1" | tr 'a-z' 'A-Z')
		TITLE="${2}"
		PAYLOAD=$(echo "${PAYLOAD}" | jq ".subject=\"[${LVL}] clamav-cron: ${TITLE}\"")
		ERROR_MSG="${3}"
		if [[ "${VPSA_IP}" == "" ]]; then
			VPSA_IP=$( ip route|awk '/default/ { print $3 }' )
		fi
#		set -x
		ERROR_MSG=$(echo "${ERROR_MSG}" | sed 's#"#\"#g')
		PAYLOAD=$(echo "${PAYLOAD}" | jq -c --arg a "${ERROR_MSG}\n\nContainer-hostname: $(hostname)" '.description=$a' | sed 's@\\\\n@\\n@g')
		curl --connect-timeout 30 -k -s -X POST -H "Content-Type: application/json" -H "X-Access-Key: ${VPSA_ACCESSKEY}" -d "${PAYLOAD}"  "https://${VPSA_IP}/api/tickets.json"
#		set +x
	fi
}

function getMounts {
	if [[ -n "${SCAN_PATH}" ]]; then
		RESULTS=$(echo "${SCAN_PATH}" | tr ' ' '\n')
	else
		RESULTS=$(mount | awk '/xfs/{print $3}' | grep -v "^${LOG_PATH}$")
	fi
	if [[ -n "${QUAR_PATH:-}" ]]; then
		echo "${RESULTS}" | grep -v "^${QUAR_PATH}$"
	else
		echo "${RESULTS}"
	fi
}

function findFiles {
	PARENT_ID=$1
	shift
	FIND_TARGET="${@}"
	if [[ -z "${FIND_TARGET}" ]]; then
		return 0
	fi
	if [[ ! -d "${FIND_TARGET}" ]]; then
		_error "[${PARENT_ID}][${FIND_TARGET}] ERROR: PATH is not a valid directory, is it mounted?"
		return 0
	fi
	FIND_HASH=$(echo "${FIND_TARGET}" | md5sum | awk '{print $1}')
	FIND_START=$(date -u +%s)
	FIND_PREFIX="${FIND_START}_${FIND_HASH}"
	FIND_ARGS=( 
		"${FIND_TARGET}"
		"-type" "f"
	)

	# Filter results for files newer than the start of the last successful scan.
	if [[ -e "${STATS_DIR}/${FIND_HASH}-find.csv" ]]; then
		LAST_LINE=$(awk '/.+,[a-f0-9]+,[0-9]+,[0-9]+/' "${STATS_DIR}/${FIND_HASH}-find.csv" | tail -n 1)
		LAST_START=$(echo "${LAST_LINE}" | cut -d',' -f3)
		LAST_END=$(echo "${LAST_LINE}" | cut -d',' -f4)
		if [[ -n "${LAST_START}" && -n "${LAST_END}" && "${LAST_START}" != "0" ]]; then
			FIND_ARGS+=( "(" "-newerct" "$(date -u --date=@${LAST_START} --rfc-3339=seconds)" "-o" "-newermt" "$(date -u --date=@${LAST_START} --rfc-3339=seconds)" ")" )
		fi
	else
		echo "volume,volume_name_md5,start_unixtime,end_unixtime,manifests_generated,configured_manifest_limit" > "${STATS_DIR}/${FIND_HASH}-find.csv"
	fi
	# 5 minute cooldown incase someone accidentally configures this to run every minute
	if [[ -n "${LAST_END}" && $(date +%s) -le $(date +%s -d "@$(( $(date +%s -d@${LAST_END}) + (60 * 5) ))") ]]; then
		_log "[${PARENT_ID}][${FIND_TARGET}] Last run was [$(date -u -d@${LAST_END} --rfc-3339=ns)] Hardcoded rate limit to 5 minutes, to reduce IO load of some environments."
		return 0
	fi
	# Parse and pass extra find critiera from FIND_FILTER env var
	if [[ -n "${FIND_EXTRA:-}" ]]; then
		OIFS=$IFS
		IFS=$'\n'
		FIND_ARGS+=( $(printf "%s" "${FIND_EXTRA}" | xargs -n 1 printf "%s\n") )
		IFS=$OIFS
	fi
	SPLIT_ARGS=(
		"-l" "${MANIFEST_LINES:-1000}"
		"-d"
		'--separator=\0'
		"--additional-suffix=.manifest"
	)
	FIND_ARGS+=("-print0")
	echo "${FIND_TARGET},${FIND_HASH},${FIND_START},,," >> "${STATS_DIR}/${FIND_HASH}-find.csv"
	_log "[$PARENT_ID][${FIND_TARGET}] - Start - \`find $(printf "'%s' " "${FIND_ARGS[@]}")\`"
	find "${FIND_ARGS[@]}" | split "${SPLIT_ARGS[@]}" - "${QUEUE_DIR}/${FIND_PREFIX}_"
	FIND_END=$(date +%s)
	LAST_MANIFEST=$(find "${QUEUE_DIR}" -iname "${FIND_PREFIX}_*" -type f -printf '%T@ %P\n' | sort -rn 2>/dev/null | head -n 1 | cut -d ' ' -f2-)
	if [[ -n "${LAST_MANIFEST}" ]]; then
		_log "[$PARENT_ID][${FIND_TARGET}] - End - Last created manifest was ${LAST_MANIFEST:-}"
	else
		_log "[$PARENT_ID][${FIND_TARGET}] - End - No manifests were generated"
	fi
	MANIFEST_COUNT=$(echo "${LAST_MANIFEST}" | sed 's/\.manifest//' | awk -F '_' '{print $NF}')
	if [[ "${FIND_START}" == "${FIND_END}" && -z "${MANIFEST_COUNT}" ]]; then
		MANIFEST_COUNT=0
	else
		MANIFEST_COUNT=$(parseSplit "${MANIFEST_COUNT:-0}")
	fi
	sed -i "s#^${FIND_TARGET},${FIND_HASH},${FIND_START},,,#${FIND_TARGET},${FIND_HASH},${FIND_START},${FIND_END},${MANIFEST_COUNT},${MANIFEST_LINES:-1000}#" "${STATS_DIR}/${FIND_HASH}-find.csv"
}

function scanQueue {
	PARENT_ID=$1
	shift
	if ! clamdRunning; then
		return
	fi
	MANIFEST_FILE="${@}"
	if [[ -e "${MANIFEST_FILE}" ]]; then
		# Take claim of the manifest file to prevent another process from using it
		mv "${MANIFEST_FILE}" "${MANIFEST_FILE}.${HOST_ID}" &> /dev/null
	fi
	if [[ -e "${MANIFEST_FILE}.${HOST_ID}" ]]; then
		COUNT=$(grep -cz '^' "${MANIFEST_FILE}.${HOST_ID}")
		_log "[$PARENT_ID] Starting ${MANIFEST_FILE} - ${COUNT} entries with ${SCAN_THREADS:-1} threads"
		env_parallel -0 -n 1 -P ${SCAN_THREADS:-1} -I {} avScan "$PARENT_ID" {} :::: "${MANIFEST_FILE}.${HOST_ID}"
		EXIT=$?
		if clamdRunning && [ ${EXIT} -eq 0 ]; then
			rm "${MANIFEST_FILE}.${HOST_ID}"
			_log "[$PARENT_ID] Ending ${MANIFEST_FILE}"
		else
			mv "${MANIFEST_FILE}.${HOST_ID}" "${MANIFEST_FILE}" &> /dev/null
			_log "[$PARENT_ID] Requeueing ${MANIFEST_FILE}. Clamd service stopped responding during this cycle. ${EXIT}"
		fi
	fi
}

function avScan {
	PARENT_ID=$1
	shift
	TARGET_FILE="${@}"
	## Scan file
	if [[ -e "${TARGET_FILE}" ]]; then # File still exists
		DATE_DIR=$(date -u +%Y/%m)
		DATE_FILE=$(date -u +%Y-%m-%d)
		if [[ ! -d "${LOG_PATH}/scans/${DATE_DIR}" ]]; then
			mkdir -p "${LOG_PATH}/scans/${DATE_DIR}"
		fi
		CLAMSCAN_ARGS=("--no-summary" "--fdpass")
		if [[ -n "${QUAR_PATH}" ]]; then
			CLAMSCAN_ARGS+=( "--move=${QUAR_PATH}" )
		fi
		CLAMSCAN_ARGS+=("${TARGET_FILE}")
		TS=$(date -u --rfc-3339=ns)
		RESULT=$(clamdscan "${CLAMSCAN_ARGS[@]}")
		EXIT_STATUS=$?
		if [[ ${EXIT_STATUS} -ge 2 || -z "${RESULT}" ]]; then
			if [[ ! -e "${TARGET_FILE}" ]]; then
				RESULT="${TARGET_FILE}: FILENOTFOUND ERROR"
			elif ! clamdRunning; then
				RESULT="${TARGET_FILE}: CLAMDSVCSTOPPED ERROR"
			else
				RESULT="${TARGET_FILE}: UNKNOWN/${EXIT_STATUS} ERROR"
			fi
		fi
		echo "${RESULT}" | awk -v prefix="[${TS}][${HOST_ID}] " '{print prefix $0}' >> "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.log"
		ISOK=": OK"
		ISERROR=" ERROR"
		length_ok=$(( ${#RESULT} - ${#ISOK} ))
		length_error=$(( ${#RESULT} - ${#ISERROR} ))
		if [[ "${RESULT:$length_ok:${#ISOK}}" != "${ISOK}" && "${RESULT:$length_error:${#ISERROR}}" != "${ISERROR}" ]]; then
			echo "${RESULT}" | awk -v prefix="[${TS}][${HOST_ID}] " '{print prefix $0}' >> "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.infected"
		elif [[ "${RESULT:$length_error:${#ISERROR}}" == "${ISERROR}" ]]; then
			echo "${RESULT}" | awk -v prefix="[${TS}][${HOST_ID}] " '{print prefix $0}' >> "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.error"
		fi
		if [[ ${EXIT_STATUS} -ge 2 ]]; then
			return 1
		else
			return 0
		fi
	else
		_log "[$PARENT_ID][${TARGET_FILE}] File not found. It's probably been moved or deleted."
	fi
}

function parseSplit {
        INPUT="${1}"
        OUTPUT=0

        LENGTH=${#INPUT}
        MOD=$(( (${LENGTH} / 2) - 1 ))
        PREF=${INPUT:0:${MOD}}
        LIT=$(echo "${INPUT:${MOD}}" | sed 's/^0*//')
	OUTPUT=$(( ${OUTPUT} + ${LIT} + (${PREF:-0} * 10) + 1 ))

        echo ${OUTPUT}
}

function requeueOrphanManifests {
	PARENT_ID=$1
	shift
	COUNT=0
	MANIFEST_LIST=( $(find "${QUEUE_DIR}/" -mindepth 1 -maxdepth 1 -type f -iname '*.manifest.*' -printf '%P\n' 2>/dev/null) )
	for MANIFEST in ${MANIFEST_LIST[@]}; do
		TARGET_HOST=${MANIFEST##*.}
		if [[ ! -e "${LOG_PATH}/hb/${TARGET_HOST}" || $(cat "${LOG_PATH}/hb/${TARGET_HOST}") < $(date -d "-11 minutes" +%s) ]]; then
			mv "${QUEUE_DIR}/${MANIFEST}" "${QUEUE_DIR}/${MANIFEST%.*}"
			COUNT=$(( ${COUNT} + 1 ))
		fi
	done
	_log "[${PARENT_ID}] ${COUNT} orphaned manifests were re-queued"
}
