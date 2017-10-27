#!/usr/bin/env bash
if [[ -x "./ssh_server.sh" ]]; then
	./ssh_server.sh &
fi
if [[ -x "./clamav_daemon.sh" ]]; then
	./clamav_daemon.sh &
fi
if [[ -x "./inotify_monitor.sh" ]]; then
	./inotify_monitor.sh "${SCAN_PATH}" &
fi

# To hold the container, though inotify will likely do it too
tail -f /var/log/dmesg
