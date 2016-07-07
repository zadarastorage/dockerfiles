#!/usr/bin/env bash

watchdir=${SCAN_PATH}

echo "Waiting for new files in ${watchdir}..."
inotifywait ${watchdir} -m -q -e close_write --format %w%f . | while IFS= read -r file; do

        echo "-------------------------------------------------------------"
        echo "Saw new file ${file} "
        if [[ "${QUAR_PATH}" != "" ]]; then
                (echo -n "$(date) -> " ;clamdscan "${file}" --move="${QUAR_PATH}" --no-summary) >> ${LOG_PATH}/clamav-scans.log
        else
                (echo -n "$(date) -> " ;clamdscan "${file}" --no-summary) >> ${LOG_PATH}/clamav-scans.log
        fi
done