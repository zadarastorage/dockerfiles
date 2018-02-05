#!/bin/bash
for x in $(ls /start/*.sh); do
	echo ${x}
	/bin/bash ${x} &
done

pids=`jobs -p`

exitcode=0

function terminate {
    trap "" CHLD

    for pid in $pids; do
        if ! kill -0 $pid 2>/dev/null; then
            wait $pid
            exitcode=$?
        fi
    done

    kill $pids 2>/dev/null
}

trap terminate CHLD
wait

exit $exitcode
