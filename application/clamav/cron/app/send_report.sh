#!/usr/bin/with-contenv bash
source /app/_functions.sh
LOCK_FILE="${LOCK_DIR}/${HOST_ID}-report.active"

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

REPORT_DATE=${1:-$(date -d "-1 day")}
DATE_DIR=$(date +%Y/%m -d "${REPORT_DATE}")
DATE_FILE=$(date +%Y-%m-%d -d "${REPORT_DATE}")

## Identify scanned and infected
SCANNED=0
if [[ -e "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.log" ]]; then
	SCANNED=$(grep -c '\(OK\|FOUND\)$' "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.log")
fi

INFECTED=0
if [[ -e "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.infected" ]]; then
	INFECTED=$(grep -c 'FOUND$' "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.infected")
fi

ERRORED=0
if [[ -e "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.error" ]]; then
	ERRORED=$(grep -c 'SCAN-ERROR$' "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.error")
fi


if [[ ! -e "${LOG_PATH}/stats/av_scan.${DATE_DIR/\//-}.csv" ]]; then
	echo "date,scanned,infected,error" > "${LOG_PATH}/stats/av_scan.${DATE_DIR/\//-}.csv"
fi

## Only log if anything was scanned at all
if [[ -e "${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.log" ]]; then
	echo "${DATE_FILE},${SCANNED}.${INFECTED},${ERRORED}" >> "${LOG_PATH}/stats/av_scan.${DATE_DIR/\//-}.csv"
fi

if [[ ${INFECTED} -eq 0 && "${REPORT_DAILY_EMPTY}" != "enabled" ]]; then
	_log "[$$] No infections were identified in yesterday's scans. Skipping notifying user."
	rm "${LOCK_FILE}"
	exit 0
fi

if [[ -z "${VPSA_ACCESSKEY}" ]]; then
	# No access key provided, can't generate ticket...
	_log "[$$] VPSA_ACCESSKEY was not defined, can't send infection report to user.."
	rm "${LOCK_FILE}"
	exit 0
fi

REPORT=(
	"Log period: ${DATE_FILE} 00:00:00 ${TZ} to ${DATE_FILE} 23:59:59 ${TZ}"
	""
	"Scan log file: ${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.log"
	"Files scanned: ${SCANNED}"
	""
	"Infection log file: ${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.infected"
	"Infections detected: ${INFECTED}"
	""
	"Error log file: ${LOG_PATH}/scans/${DATE_DIR}/${DATE_FILE}.error"
	"Scan errors detected: ${ERRORED}"
	""
	"For further details, please review logs for the day's activities on the volume directly."
	""
	"This ticket was generated automatically by a Docker container to notify the end user of potential infections detected."
	"The existance of this ticket does not mean that Zadara Support has, or is expected to, perform any operations to resolve the event."
)

RESULT=$(supportTicket "LOW" "Infection Summary for ${DATE_FILE}" "$(printf '%s\\n' "${REPORT[@]}")")
STATUS=$(echo "${RESULT}" | jq -c --raw-output '.response.status')
TICKET=$(echo "${RESULT}" | jq -c --raw-output '.response.ticket_id')
if [[ "${STATUS}" == "0" ]]; then
	_log "[$$] Support ticket #${TICKET} was generated to notify user of current results. Scanned: ${SCANNED} and Detected: ${INFECTED}"
fi

# Clean up the PID file so this can run again on next execution
rm "${LOCK_FILE}"

