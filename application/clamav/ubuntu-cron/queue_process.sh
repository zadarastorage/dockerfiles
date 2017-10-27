#!/bin/bash
SCANDIRS=( ${SCAN_PATH} )
STATSFILE="${LOG_PATH}/clamdata.csv"
QUEUEDIR="${LOG_PATH}/queue"
LOGDIR="${LOG_PATH}/scans"
LOCKDIR="/dev/shm"
IFS=$'\n'

HOSTID=$(hostname)

# Confirm this script is not already running, if so, exit
if [[ -e "${LOCKDIR}/${HOSTID}-scan.active" ]]; then
	if kill -0 $(cat ${LOCKDIR}/${HOSTID}-scan.active); then
	        exit 0
	fi
fi

echo $$ > ${LOCKDIR}/${HOSTID}-scan.active

## Functions
avFile(){
	scanobject="${1}"
	if [[ -e "${scanobject}" ]]; then # File still exists
		DATEDIR=$(date +%Y/%m)
		DATEFILE=$(date +%Y-%m-%d)
		mkdir -p ${LOGDIR}/${DATEDIR}
		if [[ "${QUAR_PATH}" != "" ]]; then
			(echo -n "$(date) -> " ;clamdscan "${scanobject}" --move="${QUAR_PATH}" --no-summary) >> ${LOGDIR}/${DATEDIR}/${DATEFILE}.log
		else
			(echo -n "$(date) -> " ;clamdscan "${scanobject}" --no-summary) >> ${LOGDIR}/${DATEDIR}/${DATEFILE}.log
		fi
	fi
}

## Logic
#TODO: Check for old inprogress files, rename to reprocess

# Find some work files in ${QUEUEDIR}
PENDINGFILES=( $(find ${QUEUEDIR}/ -mindepth 1 -maxdepth 1 -type f -mmin +2 -iname '*.log' | sort -n | head -n 20) )
# Process each line in files from ${QUEUEDIR}
while [[ ${#PENDINGFILES[@]} -gt 0 ]]; do
	for filepath in ${PENDINGFILES[@]}; do
		echo "$(date) ${filepath}"
		mv "${filepath}" "${filepath}.${HOSTID}"
		TODO=( $(cat "${filepath}.${HOSTID}" ) )
		for line in ${TODO[@]}; do
			avFile "${line}"
		done
#		mv "${filepath}.${HOSTID}" "${filepath}.completed"
		rm "${filepath}.${HOSTID}"
	done
	PENDINGFILES=( $(find ${QUEUEDIR}/ -mindepth 1 -maxdepth 1 -type f -mmin +2 -iname '*.log' | sort -n | head -n 20) )
done

rm ${LOCKDIR}/${HOSTID}-scan.active
