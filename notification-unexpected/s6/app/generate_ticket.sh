#!/bin/bash
if [[ -z "${VPSA_TOKEN}" ]]; then
        echo "[$0] VPSA_TOKEN was undefined."
        exit 1
fi
OIFS=$IFS
IFS=$'\n'
vcli=/app/vpsa_curl.sh
jq_raw='jq -c --raw-output'

TEMPLATE_FILE=""
TICKET_TITLE=""
declare -A REPLACE
while [ -n "${1}" ]; do
	case "${1}" in
		"--template")
			TEMPLATE_FILE="${2}"
			shift
			;;
		"--title")
			TICKET_TITLE="${2}"
			shift
			;;
		"--replace")
			REPLACE[${2}]="${3}"
			shift
			shift
			;;
	esac
	shift
done

TICKET_MESSAGE=$(cat "${TEMPLATE_FILE}")
for K in "${!REPLACE[@]}"; do
	TICKET_MESSAGE=$(echo "${TICKET_MESSAGE}" | sed "s@%${K}%@${REPLACE[$K]}@g")
done
IFS=$OIFS

PAYLOAD=$(echo '{}' | ${jq_raw} -n --arg subject "${TICKET_TITLE}" --arg description "${TICKET_MESSAGE}" '{subject:$subject,description:$description,zsnap:"no"}')
RESULT=$(${vcli} --token "${VPSA_TOKEN}" --method "POST" --uri "tickets.json" --payload "${PAYLOAD}")
STATUS=$(echo ${RESULT} | ${jq_raw} '.response.status')
if [[ ${STATUS} -ne 0 ]]; then
	echo "$(date -u) [$0] ERROR: Ticket generation failed, return ${RESULT}"
	exit 1
fi
