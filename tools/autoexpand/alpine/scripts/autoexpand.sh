#!/bin/ash
source /tmp/env.sh
#set -x
LOCKDIR="/dev/shm"
# Exit if another instance is still running
#exec {lock_fd}>${LOCKDIR}/autoexpand.lock || exit 1
flock -n -x "${LOCKDIR}/autoexpand.lock"
# Exit if VPSA_ACCESS_KEY is empty
if [ -z "${VPSA_ACCESS_KEY}" ]; then
	exit 1
fi
# If VPSA_IP is undefined, determine what it is
if [ -z "${VPSA_IP}" ]; then
	VPSA_IP=$( ip route|awk '/default/ { print $3 }' )
fi

# DEFAULTS
VOLUME_MAX=${VOLUME_MAX:-102400} # 100TB in GB
VOLUME_INCREASE_BY_PERCENT=${VOLUME_INCREASE_BY_PERCENT:-5}
VOLUME_INCREASE_BY_GB=${VOLUME_INCREASE_BY_GB:-512} # half TB
VOLUME_FREE_PERCENT=${VOLUME_FREE_PERCENT:-5} # 5% free
VOLUME_FREE_GB=${VOLUME_FREE_GB:-100} # 100GB free
if [ -z "${VOLUME_EXPAND_CRITERIA}" ]; then
	VOLUME_EXPAND_CRITERIA="any" # any,percent,gb
fi
if [ -z "${VOLUME_EXPAND_METHOD}" ]; then
	VOLUME_EXPAND_METHOD="largest" # largest,smallest,percent,gb
fi
if [ -z "${GENERATE_TICKET}" ]; then
	GENERATE_TICKET="enabled" # largest,smallest,percent,gb
fi

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
	CMD="curl -k -s --connect-timeout 30 -A 'tool-autoexpand' -H 'Content-Type: application/json' -H 'X-Access-Key: ${VPSA_ACCESS_KEY}'"
	CMD="${CMD} -X '${METHOD}'"
	if [ -n "${PAYLOAD}" ]; then
		CMD="${CMD} -d '${PAYLOAD}'"
	fi
	CMD="${CMD} https://${VPSA_IP}/api/${URI}"
#	(>&2 echo ${CMD} )
	eval ${CMD} | jq -c --raw-output '.'
}

function generateTicket {
	VOLUME_ID="${1}"
	VOLUME_NAME="${2}"
	SIZE_GB="${3}"
	FREE_GB="${4}"
	EXPANDED_BY="${5}"
	NEWSIZE_GB=$(dc "${SIZE_GB} ${EXPANDED_BY} + p" | cut -d'.' -f1)
	if [ -n "${VPSA_ACCESS_KEY}" -a "${GENERATE_TICKET}" == "enabled" ]; then
		PAYLOAD="{}"
		SUBJECT="Volume ${VOLUME_NAME} (${VOLUME_ID}) was autoexpanded by ${EXPANDED_BY}GB to ${NEWSIZE_GB}GB"
		DESCRIPTION="Volume '${VOLUME_NAME}' had ${FREE_GB}GB of ${SIZE_GB}GB Available.
It was expanded by ${EXPANDED_BY}GB to ${NEWSIZE_GB}GB.

This container is configured as follows:
VOLUME_INCREASE_BY_PERCENT=${VOLUME_INCREASE_BY_PERCENT}
VOLUME_INCREASE_BY_GB=${VOLUME_INCREASE_BY_GB}
VOLUME_FREE_PERCENT=${VOLUME_FREE_PERCENT}
VOLUME_FREE_GB=${VOLUME_FREE_GB}
VOLUME_EXPAND_CRITERIA=${VOLUME_EXPAND_CRITERIA}
VOLUME_EXPAND_METHOD=${VOLUME_EXPAND_METHOD}"
		PAYLOAD=$(echo '{}' | jq -c --raw-output --arg subject "${SUBJECT}" --arg desc "${DESCRIPTION}" '{subject:$subject,description:$desc}')
		vpsaAPI -m POST -p "${PAYLOAD}" -u "tickets.json"
	fi
}

function expandVolume {
	VOLUME_ID="${1}"
	VOLUME_NAME="${2}"
	SIZE_GB="${3}"
	FREE_GB="${4}"
	INCREASE_BY_GB=""
	case "${VOLUME_EXPAND_METHOD}" in
		"largest")
			INCREASE_BY_GB=$(dc "${SIZE_GB} ${VOLUME_INCREASE_BY_PERCENT} 100 / * p" | cut -d '.' -f1)
			if [ ${INCREASE_BY_GB} -lt ${VOLUME_INCREASE_BY_GB} ]; then
				INCREASE_BY_GB=${VOLUME_INCREASE_BY_GB}
			fi
			;;
		"smallest")
			INCREASE_BY_GB=$(dc "${SIZE_GB} ${VOLUME_INCREASE_BY_PERCENT} 100 / * p" | cut -d'.' -f1)
			if [ ${INCREASE_BY_GB} -gt ${VOLUME_INCREASE_BY_GB} ]; then
				INCREASE_BY_GB=${VOLUME_INCREASE_BY_GB}
			fi
			;;
		"percent")
			INCREASE_BY_GB=$(dc "${SIZE_GB} ${VOLUME_INCREASE_BY_PERCENT} 100 / * p" | cut -d'.' -f1)
			;;
		"gb")
			INCREASE_BY_GB=${VOLUME_INCREASE_BY_GB}
			;;
	esac
	if [ ${INCREASE_BY_GB} -eq 0 ]; then
		INCREASE_BY_GB=1
	fi
#	echo "${INCREASE_BY_GB}"
	OUTCOME=$(dc "${SIZE_GB} ${INCREASE_BY_GB} + p")
	if [ ${OUTCOME} -gt ${VOLUME_MAX} ]; then
		INCREASE_BY_GB=$(dc "${VOLUME_MAX} ${SIZE_GB} - p" | cut -d'.' -f1)
		if [ "${INCREASE_BY_GB:0:1}" == "-" ]; then
			INCREASE_BY_GB=0
		fi
	fi
	if [ -n "${INCREASE_BY_GB}" -a ${INCREASE_BY_GB} -gt 0 ]; then
		PAYLOAD=$(echo "{}"|jq -c --raw-output --arg increase "${INCREASE_BY_GB}G" '.capacity=$increase')
		vpsaAPI -m 'post' -u "volumes/${VOLUME_ID}/expand.json" -p "${PAYLOAD}"
		sleep 1s
		generateTicket "${VOLUME_ID}" "${VOLUME_NAME}" "${SIZE_GB}" "${FREE_GB}" "${INCREASE_BY_GB}"
		sleep 1s
	fi
}

OIFS=$IFS
IFS=$'\n'
# Logic
# Obtain list of volumes
VOLUMES=$(vpsaAPI -m 'get' -u 'volumes.json' | jq -c --raw-output '.response.volumes[]')
for entry in ${VOLUMES}; do
	VOLUME_NAME=$(echo "${entry}" | jq -c --raw-output '.name')
	VOLUME_DISPLAY=$(echo "${entry}" | jq -c --raw-output '.display_name')
	VOLUME_CAPACITY=$(echo "${entry}" | jq -c --raw-output '.virtual_capacity')
	## Determine usage
	USAGE_GB=$(echo "${entry}" | jq -c --raw-output '.allocated_capacity' | cut -d '.' -f1)
	USAGE_PERCENT=$(dc "100 ${USAGE_GB} ${VOLUME_CAPACITY} / * p")
	FREE_GB=$(dc "${VOLUME_CAPACITY} ${USAGE_GB} - p" | cut -d '.' -f1)
	FREE_PERCENT=$(dc "100 ${USAGE_PERCENT} - p")
#	echo "${VOLUME_NAME} / ${VOLUME_DISPLAY} - ${VOLUME_CAPACITY}GB -- ${USAGE_GB}GB (${USAGE_PERCENT}%)"
	EXCEEDS_GB=$(dc "${FREE_GB} ${VOLUME_FREE_GB} - p" | cut -d '.' -f1)
	EXCEEDS_PERCENT=$(dc "${FREE_PERCENT} ${VOLUME_FREE_PERCENT} - p")
	if [ "${EXCEEDS_PERCENT:0:1}" == "-" -o "${EXCEEDS_GB:0:1}" == "-" ] ; then
		## If criteria, then expand by other criteria
#		echo "${VOLUME_NAME} / ${VOLUME_DISPLAY} - ${VOLUME_CAPACITY}GB -- ${USAGE_GB}GB (${USAGE_PERCENT}%)"
#		echo "EXCEEDS: ${EXCEEDS_GB}GB ${EXCEEDS_PERCENT}%"
		case "${VOLUME_EXPAND_CRITERIA}" in
			"any")
				expandVolume "${VOLUME_NAME}" "${VOLUME_DISPLAY}" "${VOLUME_CAPACITY}" "${FREE_GB}"
				;;
			"percent")
				if [ "${EXCEEDS_PERCENT:0:1}" == "-" ]; then
					expandVolume "${VOLUME_NAME}" "${VOLUME_DISPLAY}" "${VOLUME_CAPACITY}" "${FREE_GB}"
				fi
				;;
			"gb")
				if [ "${EXCEEDS_GB:0:1}" == "-" ]; then
					expandVolume "${VOLUME_NAME}" "${VOLUME_DISPLAY}" "${VOLUME_CAPACITY}" "${FREE_GB}"
				fi
				;;
		esac
	fi
done
IFS=$OIFS
flock -u "${LOCKDIR}/autoexpand.lock"
