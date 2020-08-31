#!/bin/bash
date -u > /lastrun

# Functions
function _log {
	(>&2 echo "$(date +'%Y-%m-%d %H:%M:%S') ${0}: ${@}")
}

# Function to validate "empty" results from jq, possibly due to missing data
function isEmpty {
	if [[ -n "${@}" && "${@}" != "null" ]]; then
		return 1
	fi
	return 0
}

if [[ -z "${VPSA_TOKEN}" ]]; then
	_log "VPSA_TOKEN was undefined."
	exit 1
fi

# Script mutex handling
scriptname=$(basename $0)
pidfile="/var/run/${scriptname}"
exec 200>$pidfile
flock -n 200 || exit 1
pid=$$
echo $pid 1>&200


# Defaults and paths
vcli=/app/vpsa_curl.sh
ticket=/app/generate_ticket.sh
ticket_template=/app/ticket_text.txt
jq_raw='jq -c --raw-output'
DATA_LIMIT=10
CUTOFF_UNIX=$(date -d "-6 hours" +%s)
SEARCH="Unexpected VC"

# Walk backwards from most recent controller logs
## Check for "setting to active role was initiated."
## Check for SEARCH value
CONT=1
COUNT=1
OFFSET=0
ACTIVE_MARK=""
ACTIVE_SOURCE=""
UNEXPECTED_MARK=""
UNEXPECTED_SOURCE=""
UNEXPECTED_MSG=""
UNEXPECTED_UNIX=""
while [[ ${CONT} -eq 1 ]]; do
	SORT=$(jq -n -c --raw-output '[{"property":"msg-id","direction":"DESC"}] | @uri')
	RESULTS=$(${vcli} --token "${VPSA_TOKEN}" --method "get" --uri "messages.json?limit=${DATA_LIMIT}&start=${OFFSET}&attr_key=controller&sort=${SORT}" | ${jq_raw} '.response.messages')
	RESULTS_SIZE=$(echo ${RESULTS} | ${jq_raw} '. | length')

	# Time that controller begun "activation" process
	if isEmpty "${ACTIVE_MARK}"; then
		ACTIVE_MARK=$(echo ${RESULTS} | ${jq_raw} --arg needle "setting to active role was initiated." '[ .[] | select(.msg_title | contains($needle)) ][0].msg_id')
		if ! isEmpty "${ACTIVE_MARK}"; then
			ACTIVE_SOURCE=$(echo ${RESULTS} | ${jq_raw} --arg msg_id "${ACTIVE_MARK}" '.[] | select(.msg_id==$msg_id).msg_attributes[] | select(.key=="controller").value')
		fi
	fi
	# Time that search string occurred
	if isEmpty "${UNEXPECTED_MARK}"; then
		UNEXPECTED_MARK=$(echo ${RESULTS} | ${jq_raw} --arg needle "${SEARCH}" '[ .[] | select(.msg_title | contains($needle)) ][0].msg_id')
		if ! isEmpty "${UNEXPECTED_MARK}"; then
			UNEXPECTED_SOURCE=$(echo ${RESULTS} | ${jq_raw} --arg msg_id "${UNEXPECTED_MARK}" '.[] | select(.msg_id==$msg_id).msg_attributes[] | select(.key=="controller").value')
			UNEXPECTED_MSG=$(echo ${RESULTS} | ${jq_raw} --arg msg_id "${UNEXPECTED_MARK}" '.[] | select(.msg_id==$msg_id).msg_title')
			UNEXPECTED_TIME=$(echo ${RESULTS} | ${jq_raw} --arg msg_id "${UNEXPECTED_MARK}" '.[] | select(.msg_id==$msg_id).msg_time')
			if ! isEmpty "${UNEXPECTED_TIME}"; then
				UNEXPECTED_UNIX=$(date -d "${UNEXPECTED_TIME}" +%s)
			fi
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
			( ${COUNT} -gt 1 && ${RESULTS_SIZE} -lt ${DATA_LIMIT} ) ||
			( ${END_UNIX} -lt ${CUTOFF_UNIX} )
	]]; then
		CONT=0
	fi
done

# Exit(dont generate ticket) if:
## no unexpected events detected
## unexpected event predates current activation time
## unexpected event is older than cutoff
## Current activation is from different controller than unexpected event
if 
	isEmpty "${ACTIVE_MARK}" ||
	isEmpty "${UNEXPECTED_MARK}" ||
	isEmpty "${ACTIVE_SOURCE}" ||
	isEmpty "${UNEXPECTED_SOURCE}" ||
	[[ ${UNEXPECTED_MARK} -lt ${ACTIVE_MARK} ]] ||
	[[ ${UNEXPECTED_UNIX} -lt ${CUTOFF_UNIX} ]] ||
	[[ "${ACTIVE_SOURCE}" != "${UNEXPECTED_SOURCE}" ]]; then
	exit 0
fi

# Exit if we've reported this event already
if [[ -e /unexpected && $(cat /unexpected) -ge ${UNEXPECTED_MARK} ]]; then
	exit 0
fi

# If we've gotten this far, generate ticket
_log "Generating ticket, unexpected event was detected."
TICKET_ID=$(echo "${UNEXPECTED_MSG}" | sed 's@.* ticket \([0-9]*\): .*@\1@g' )
${ticket} --template "${ticket_template}" --title "Unexpected event was detected in ticket #${TICKET_ID}" --replace TICKET_ID "${TICKET_ID}" --replace MESSAGE "${UNEXPECTED_MSG}" --replace TIME "$(date -d "@${UNEXPECTED_UNIX}" -u)"
if [[ $? -eq 0 ]]; then
	echo "${UNEXPECTED_MARK}" > /unexpected
fi
