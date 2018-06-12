#!/bin/ash
source /tmp/env.sh
#set -x
LOCKDIR="/dev/shm"
# Exit if another instance is still running
#exec {lock_fd}>${LOCKDIR}/zprivnotification.lock || exit 1
#flock -n -x "${LOCKDIR}/zprivnotification.lock"
# Exit if VPSA_ACCESS_KEY is empty
if [ -e "${LOCKDIR}/zprivnotification.lock" ]; then
	exit 1
fi
touch "${LOCKDIR}/zprivnotification.lock"
if [ -z "${VPSA_ACCESS_KEY}" ]; then
	exit 1
fi
# If VPSA_IP is undefined, determine what it is
if [ -z "${VPSA_IP}" ]; then
	VPSA_IP=$( ip route|awk '/default/ { print $3 }' )
fi
LOG_LIMIT=${LOG_LIMIT:-100}

# DEFAULTS
if [ -z "${GENERATE_TICKET}" ]; then
	GENERATE_TICKET="enabled" # largest,smallest,percent,gb
fi
SEARCH_STRING="SSH privileged access to the VC over port 2023 is "

# Functions
function vpsaAPI {
	while [ -n "${1}" ]; do
		case "${1}" in
			"-u")
				URI="${2}"
				shift
				;;
			"-m")
				METHOD="$(echo ${2} | tr '[a-z]' '[A-Z]')"
				shift
				;;
			"-p") # Payload
				PAYLOAD="${2}"
				shift
				;;
		esac
		shift
	done
	CMD="curl -k -s --connect-timeout 30 -A 'tool-zprivnotification' -H 'Content-Type: application/json' -H 'X-Access-Key: ${VPSA_ACCESS_KEY}'"
	CMD="${CMD} -X '${METHOD}'"
	if [ -n "${PAYLOAD}" ]; then
		CMD="${CMD} -d '${PAYLOAD}'"
	fi
	CMD="${CMD} 'https://${VPSA_IP}/api/${URI}'"
#	(>&2 echo ${CMD} )
	eval ${CMD} | jq -c --raw-output '.'
}

function generateTicket {
	if [ -n "${VPSA_ACCESS_KEY}" -a "${GENERATE_TICKET}" == "enabled" ]; then
		SUBJECT="VPSA privileged access events detected"
		DESCRIPTION="VPSA privileged access has been detected at the following times:
Time,LogID#,Message
$(jq -c --raw-output 'sort_by(.time)|reverse[]|[.time,.id,.message]|@csv' "${LOCKDIR}/activity.tmp" | head -n 100 | tr -d '"')"
		PAYLOAD=$(jq -n -c --raw-output --arg subject "${SUBJECT}" --arg desc "${DESCRIPTION}" '{subject:$subject,description:$desc}')
		vpsaAPI -m POST -p "${PAYLOAD}" -u "tickets.json"
	fi
}

OIFS=$IFS
IFS=$'\n'
# Logic
## Track last run, should do a full rescan on first deploy or redeploy, won't rescan on failover
LAST_TMP="/srv/lastid"
touch ${LAST_TMP}
LAST_ID=$(cut -d',' -f1 "${LAST_TMP}")
if [ -z "${LAST_ID}" ] || [ "${LAST_ID}" == "null" ]; then
	LAST_ID=0
fi
#LAST_UNIX=$(cut -d',' -f2 "${LAST_TMP}")
#if [ -z "${LAST_UNIX}"]; then
#fi

# Start the scanning loop, construct history of events
echo '[]' > "${LOCKDIR}/activity.tmp"
SORT=$(jq -n -c --raw-output '[{"property":"msg-id","direction":"ASC"}]|@uri')
FIRST_ID=$(vpsaAPI -m 'get' -u "messages.json?limit=1&sort=${SORT}&start=0" | jq -c --raw-output '.response.messages[0].msg_id')
CONT=1
while [ ${CONT} -eq 1 ]; do
#	URI="messages.json?limit=${LOG_LIMIT}&sort=${SORT}&start=${LAST_ID}&attr_key=controller" ## Start # is applied to the idx after the filter, not the msg_id... >.<
	OFFSET=$(dc "${LAST_ID} ${FIRST_ID} - p")
	URI="messages.json?limit=${LOG_LIMIT}&sort=${SORT}&start=${OFFSET}"
	RESULTS=$(vpsaAPI -m 'get' -u "${URI}" | jq -c --raw-output '.response.messages')
	if [ "${RESULTS}" != "null" ] && [ -n "${RESULTS}" ]; then
		COUNT=$(echo "${RESULTS}" | jq -c --raw-output 'length')
		if [ ${COUNT} -eq 0 ]; then
			CONT=0
		else
			LAST_ID=$(echo "${RESULTS}" | jq -c --raw-output '.[-1].msg_id')
			echo "${RESULTS}" | jq -c --raw-output --arg search_string "${SEARCH_STRING}" '[.[]|select(.msg_title | contains($search_string))|{id:.msg_id,time:.msg_time,message:.msg_title}]' > "${LOCKDIR}/activity.tmp2"
			jq -c --raw-output -s '.[0] as $o1 | .[1] as $o2 | ($o1 + $o2)' "${LOCKDIR}/activity.tmp" "${LOCKDIR}/activity.tmp2" > "${LOCKDIR}/activity.tmp3"
			rm "${LOCKDIR}/activity.tmp" "${LOCKDIR}/activity.tmp2"
			mv "${LOCKDIR}/activity.tmp3" "${LOCKDIR}/activity.tmp"
		fi
	else
		## ERROR CASE... TODO: Detect and deal with this
		CONT=0
	fi
done
# Submit support ticket listing out when 2023 was opened and by who
if [ $(jq 'length' "${LOCKDIR}/activity.tmp") -ne 0 ]; then
	jq '.' "${LOCKDIR}/activity.tmp"
	generateTicket
fi
# Log the LAST_ID and unixtime to the lastrun file
echo "${LAST_ID}" > "${LAST_TMP}"
IFS=$OIFS
#flock -u "${LOCKDIR}/zprivnotification.lock"
rm "${LOCKDIR}/zprivnotification.lock"
