#!/bin/bash
if [[ -z "${VPSA_TOKEN}" ]]; then
	echo "[$0] VPSA_TOKEN was undefined."
	exit 1
fi

# Script mutex handling
scriptname=$(basename $0)
pidfile="/var/run/${scriptname}"
exec 200>$pidfile
flock -n 200 || exit 1
pid=$$
echo $pid 1>&200

date -u > /lastrun

# Defaults and paths
vcli=/app/vpsa_curl.sh
ticket=/app/generate_ticket.sh
ticket_template=/app/ticket_text.txt
jq_raw='jq -c --raw-output'
DATA_LIMIT=10
CUTOFF_UNIX=$(date -d "-6 hours" +%s)
SEARCH="Unexpected VC"

# Function to validate "empty" results from jq, possibly due to missing data
function isEmpty {
	if [[ -n "${@}" && "${@}" != "null" ]]; then
		return 1
	fi
	return 0
}

# Determine current active/standby state
CONTROLLERS=""
VC_ACTIVE=""
VC_STANDBY=""
VC_ACTIVE_TIME=""

# Retry incase controller state is still syncronizing
while isEmpty "${CONTROLLERS}" || isEmpty "${VC_ACTIVE}" || isEmpty "${VC_STANDBY}" || isEmpty "${VC_ACTIVE_TIME}"; do
	CONTROLLERS=$(${vcli} --token "${VPSA_TOKEN}" --method "get" --uri "vcontrollers.json" | ${jq_raw} '.response.vcontrollers')
	VC_ACTIVE=$(echo ${CONTROLLERS} | ${jq_raw} '.[]|select(.state=="active").name')
	VC_ACTIVE_TIME=$(echo ${CONTROLLERS} | ${jq_raw} '.[]|select(.state=="active").sod_end_time')
	VC_STANDBY=$(echo ${CONTROLLERS} | ${jq_raw} '.[]|select(.state=="standby").name')
	if isEmpty "${VC_ACTIVE}" || isEmpty "${VC_STANDBY}"; then
		sleep 2s
	fi
done

# Determine when container was created
DOCKER_ID=$(hostname)
CONTAINER=$(${vcli} --token "${VPSA_TOKEN}" --method "get" --uri "containers.json" | ${jq_raw} --arg id "${DOCKER_ID}" '.response.containers[]|select( .docker_id | startswith($id) )')
CONTAINER_TIME=$(echo ${CONTAINER} | ${jq_raw} '.created_at')


# We're only going to check for unexpected if the current active occurred after container creation
if ! isEmpty "${CONTAINER_TIME}"; then
	CONTAINER_UNIX=$(date -d "${CONTAINER_TIME}" +%s)
	ACTIVE_UNIX=$(date -d "${VC_ACTIVE_TIME}" +%s)
	if [[ ${CONTAINER_UNIX} -ge ${ACTIVE_UNIX} ]]; then
		echo "[$0] Active controller was active when the container was created, nothing has changed."
		exit 0
	fi
fi

# Walk backwards from most recent active controller log
## Check for "setting to active role was initiated."
## Check for SEARCH value
CONT=1
COUNT=1
OFFSET=0
ACTIVE_MARK=""
UNEXPECTED_MARK=""
UNEXPECTED_MSG=""
UNEXPECTED_UNIX=""
while [[ ${CONT} -eq 1 ]]; do
	SORT=$(jq -n -c --raw-output '[{"property":"msg-id","direction":"DESC"}]|@uri')
	RESULTS=$(${vcli} --token "${VPSA_TOKEN}" --method "get" --uri "messages.json?limit=${DATA_LIMIT}&start=${OFFSET}&attr_key=controller&attr_value=${VC_ACTIVE}&sort=${SORT}" | ${jq_raw} '.response.messages')
	RESULTS_SIZE=$(echo ${RESULTS} | ${jq_raw} '. | length')

	# Time that controller begun "activation" process
	if isEmpty "${ACTIVE_MARK}"; then
		ACTIVE_MARK=$(echo ${RESULTS} | ${jq_raw} --arg needle "setting to active role was initiated." '[.[]|select(.msg_title | contains($needle))][0].msg_id')
	fi
	# Time that search string occurred
	if isEmpty "${UNEXPECTED_MARK}"; then
		UNEXPECTED_MARK=$(echo ${RESULTS} | ${jq_raw} --arg needle "${SEARCH}" '[.[]|select(.msg_title | contains($needle))][0].msg_id')
		UNEXPECTED_MSG=$(echo ${RESULTS} | ${jq_raw} --arg needle "${SEARCH}" '[.[]|select(.msg_title | contains($needle))][0].msg_title')
		UNEXPECTED_TIME=$(echo ${RESULTS} | ${jq_raw} --arg needle "${SEARCH}" '[.[]|select(.msg_title | contains($needle))][0].msg_time')
		if ! isEmpty "${UNEXPECTED_TIME}"; then
			UNEXPECTED_UNIX=$(date -d "${UNEXPECTED_TIME}" +%s)
		fi
	fi
	END_TIME=$(echo ${RESULTS} | ${jq_raw} '.[-1].msg_time')
	END_UNIX=$(date -d "${END_TIME}" +%s)

#	echo ${RESULTS} | jq '.[].msg_id'
#	echo "END(${RESULTS_SIZE})"

	COUNT=$(( ${COUNT} + 1 ))
	OFFSET=$(( ${DATA_LIMIT} + ${OFFSET} ))

	# Exit cases:
	## When we've found the most recent unexpected AND most recent active initiation
	## We've traversed X hours of logs
	## Current page > 1 and results are less than DATA_LIMIT
	if [[
		( ${ACTIVE_MARK} -gt 0 && ${UNEXPECTED_MARK} -gt 0 ) ||
			( ${END_UNIX} -lt ${CUTOFF_UNIX} ) ||
			( ${COUNT} -gt 1 && ${RESULTS_SIZE} -lt ${DATA_LIMIT} )
	]]; then
		CONT=0
	fi
done

# Exit(dont generate ticket) if:
## no unexpected events detected
## unexpected event predates current activation time
## unexpected event is older than cutoff
if isEmpty "${ACTIVE_MARK}" || isEmpty "${UNEXPECTED_MARK}" || [[ ${UNEXPECTED_MARK} -lt ${ACTIVE_MARK} || ${UNEXPECTED_UNIX} -lt ${CUTOFF_UNIX} ]]; then
	exit 0
fi

# Exit if we've reported this event already
if [[ -e /unexpected && $(cat /unexpected) -ge ${UNEXPECTED_MARK} ]]; then
	exit 0
fi

# If we've gotten this far, generate ticket
echo "Generating ticket"
TICKET_ID=$(echo "${UNEXPECTED_MSG}" | sed 's@.* ticket \([0-9]*\): .*@\1@g' )
${ticket} --template "${ticket_template}" --title "Unexpected event was detected in ticket #${TICKET_ID}" --replace TICKET_ID "${TICKET_ID}" --replace MESSAGE "${UNEXPECTED_MSG}" --replace TIME "$(date -d "@${UNEXPECTED_UNIX}" -u)"
if [[ $? -eq 0 ]]; then
	echo "${UNEXPECTED_MARK}" > /unexpected
fi
