#!/bin/bash
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
	       set -x
	       ERROR_MSG=$(echo "${ERROR_MSG}" | sed 's#"#\"#g')
		PAYLOAD=$(echo "${PAYLOAD}" | jq -c --arg a "${ERROR_MSG}\n\nContainer-hostname: $(hostname)" '.description=$a' | sed 's@\\\\n@\\n@g')
		curl --connect-timeout 30 -k -s -X POST -H "Content-Type: application/json" -H "X-Access-Key: ${VPSA_ACCESSKEY}" -d "${PAYLOAD}"  "https://${VPSA_IP}/api/tickets.json"
	       set +x
	fi
}
