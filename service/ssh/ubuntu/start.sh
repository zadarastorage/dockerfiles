#!/bin/bash
if [ -d '/runonce' ]; then
	for x in $(ls /runonce/*.sh); do
		echo ${x}
		/bin/bash ${x}
	done
fi
for x in $(ls /start/*.sh); do
	echo ${x}
	/bin/bash ${x} &
done

pids=`jobs -p`

exitcode=0

function _term() {
    echo "Caught SIGTERM signal!"
    kill -TERM $pids 2>/dev/null
}


function _chld {
    trap "" CHLD

    for pid in $pids; do
        if ! kill -0 $pid 2>/dev/null; then
            wait $pid
            exitcode=$?
        fi
    done

    kill $pids 2>/dev/null
}

trap _term TERM
trap _chld CHLD
wait

exit $exitcode
