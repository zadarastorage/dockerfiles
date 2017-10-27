#!/bin/sh
for x in $(ls /start/*.sh); do
	/bin/sh ${x}
done

exec "$@"

while : ; do
	sleep 10m
done
