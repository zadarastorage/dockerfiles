#!/bin/sh
for x in $(ls /start/*.sh); do
	/bin/bash ${x}
done

exec "$@"

while : ; do
	sleep 10m
done
