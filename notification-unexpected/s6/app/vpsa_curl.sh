#!/usr/bin/with-contenv bash
OIFS=$IFS
IFS=$'\n'
CURL_IP=""
CURL_TOKEN=""
CURL_METHOD="GET"
CURL_URI=""
CURL_PAYLOAD=""
CURL_CONTENT_TYPE="application/json"
CURL_ARGS=("--connect-timeout" "10" "-L" "-s" "-k" "-A" "vpsa_curl")

function _log {
        (>&2 echo "$(date +'%Y-%m-%d %H:%M:%S') ${0}: ${@}")
}

while [ -n "${1}" ]; do
	case "${1}" in
		"-i"|"--ip")
			CURL_IP="${2}"
			shift
			;;
		"-t"|"--token")
			CURL_TOKEN="${2}"
			shift
			;;
		"-m"|"--method")
			CURL_METHOD="$(echo ${2} | tr '[a-z]' '[A-Z]')"
			shift
			;;
		"-u"|"--uri")
			CURL_URI="${2}"
			shift
			;;
		"-p"|"--payload")
			CURL_PAYLOAD="${2}"
			shift
			;;
	esac
	shift
done

# Check for IP env var or use default route(docker parent)
if [[ -z "${CURL_IP}" ]]; then
	if [[ -n "${VPSA_IP}" ]]; then
		CURL_IP="${VPSA_IP}"
	else
		CURL_IP=$( ip route|awk '/default/ { print $3 }' )
	fi
fi

# Fail if no endpoint
if [[ -z "${CURL_URI}" ]]; then
	_log "--uri flags were not specified, exiting."
	exit 1
fi

# Add standard args
CURL_ARGS+=( "-X" "${CURL_METHOD}" "--header" "Content-Type: ${CURL_CONTENT_TYPE}" )

# VPSA API token
if [ -n "${CURL_TOKEN}" ]; then
	CURL_ARGS+=( "--header" "X-Token: ${CURL_TOKEN}" )
fi

# Request payload
if [ -n "${CURL_PAYLOAD}" ]; then
	CURL_ARGS+=( "-d" "${CURL_PAYLOAD}" )
fi

# Full URL
CURL_ARGS+=( "https://${CURL_IP}/api/${CURL_URI}" )

# Rate limiting
CURL_LAST=$(cat /tmp/lastapi-${CURL_IP} 2>/dev/null)
while [[ -n "${CURL_LAST}" && $(( $(date +%s) - ${CURL_LAST} )) < ${CURL_SLEEP:-1} ]]; do
	sleep 1s
done

# Perform request
CURL_RESULT=$(curl ${CURL_ARGS[@]})
date +%s > "/tmp/lastapi-${CURL_IP}"
CURL_ERROR=$(echo "${CURL_RESULT}" | jq -c --raw-output 'if .status != null then .status!=0 else .response.status!=0 end')
if [[ "${CURL_ERROR}" != "false" ]]; then
	_log "ERROR: [${CURL_METHOD}] ${CURL_IP}/api/${CURL_URI} -> $(echo "${CURL_RESULT}"| jq -c --raw-output '.')"
	## There was an error, sleep for 5s to help back off if VPSA is overloaded
	sleep 5s
fi
echo ${CURL_RESULT} | jq -c --raw-output '.'

IFS=$OIFS
