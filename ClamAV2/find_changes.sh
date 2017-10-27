#!/bin/bash
SCANDIRS=( ${SCAN_PATH} )
STATSFILE="${LOG_PATH}/clamdata.csv"
QUEUEDIR="${LOG_PATH}/queue"
LOCKDIR="/dev/shm"
CURRENTTIME=$(date +%s)
IFS=$'\n'

SINCELASTSCAN=3600 # Seconds since last completed scan before we scan again (delay)
LINESPER=500 # Max lines per resulting log file
SKIPDELAY=$(expr ${SINCELASTSCAN} / 6)
HOSTID=$(hostname)
# CSV order: [target],[last scan start unixtime],[last scan end unixtime],[runtime in seconds],[changed in last scan]

# Check/create all relevant directories
if [[ -d "${LOG_PATH}" && ! -d "${QUEUEDIR}" ]]; then
	mkdir ${QUEUEDIR}
fi

# Confirm this script is not already running, if so, exit
if [[ -e "${LOCKDIR}/${HOSTID}-find.active" ]]; then
	exit 0
else
	echo $$ > ${LOCKDIR}/${HOSTID}-find.active
fi


## Functions
performScan(){
	scantarget="${5}"
	laststart=${1}
	lastend=${2}
	lastrun=${3}
	lastnew=${4}
	nextpossiblescan=$(expr ${lastend} + ${SINCELASTSCAN})
	if [[ $(date +%s) -ge ${nextpossiblescan} || ${lastrun} -lt ${SKIPDELAY} ]]; then # stall the scan for an hour if it completed recently, unless it usually takes less than X time to run(1/6th of the delay)
		difference=$(expr $(date +%s) - ${laststart})
		newstart=$(date +%s)
		newerthan=$(expr ${difference} \* 2)
		newerthan=$(expr ${newstart} - ${newerthan})
		# Update stats file with new laststart
		sed -i "s#^${scantarget},${laststart}#${scantarget},${newstart}#g" ${STATSFILE}
		find ${scantarget} -type f -newermt "$(date --date=@${newerthan})" | split -l ${LINESPER} --additional-suffix='.log' - ${QUEUEDIR}/${newstart}_
		newend=$(date +%s)
		newtime=$(expr ${newend} - ${newstart})
		newchange=$(cat ${QUEUEDIR}/${newstart}_* | wc -l )
		# Update stats file with new lastend, new lastrun and new lastchange
#		sed -i "s#^${scantarget},.*#${scantarget},${newstart},${newend},${newtime},${newchange}#g" ${STATSFILE}
		sed -i "s#^${scantarget},${newstart},${lastend},${lastrun},${lastnew}#${scantarget},${newstart},${newend},${newtime},${newchange}#g" ${STATSFILE}
	fi
}

### Logic
# Make sure we're watching for all declared directories
for watch in ${SCANDIRS[@]}; do
	# Check if watch is in the statistics csv
	if grep --quiet "^${watch}," ${STATSFILE}; then
		# Exists
		echo "$(date) ${watch}: Exists"
	else
		# Doesn't exist
		echo "$(date) ${watch}: New"
		echo "${watch},,,," >> ${STATSFILE}
	fi
done

# Sort stats file for oldest scan
sort ${STATSFILE} -o ${STATSFILE} -t "," -n -k2 -k4 -k3 -k1

# Read in the statsfile and start searching for data change
ENTRIES=( $(cat ${STATSFILE}) )
for entry in ${ENTRIES[@]}; do
	scantarget=$(echo ${entry} | cut -d ',' -f1)
	laststart=$(echo ${entry} | cut -d ',' -f2 )
	lastend=$(echo ${entry} | cut -d ',' -f3)
	lastrun=$(expr ${lastend} - ${laststart})
	lastnew=$(echo ${entry} | cut -d ',' -f5)
	if [[ "${scantarget}" != "" && -d "${scantarget}" ]]; then
		if [[ "${laststart}" != "" && "${lastend}" != "" ]]; then
			performScan "${laststart}" "${lastend}" "${lastrun}" "${lastnew}"  "${scantarget}"
		else # New directory, scan it for all files
			newstart=$(date +%s)
			find "${scantarget}" -type f | split -l ${LINESPER} --additional-suffix='.log' - ${QUEUEDIR}/${newstart}_
			newend=$(date +%s)
			newtime=$(expr ${newend} - ${newstart})
			newchange=$(cat ${QUEUEDIR}/${newstart}_* | wc -l )
			# Update stats file with new lastend, new lastrun and new lastchange
			sed -i "s#^${scantarget},.*#${scantarget},${newstart},${newend},${newtime},${newchange}#g" ${STATSFILE}
		fi
	fi
	sleep 1s # Ensures that the date function should be different on each pass
done

# Clean up the PID file so this can run again on next execution
rm ${LOCKDIR}/${HOSTID}-find.active
