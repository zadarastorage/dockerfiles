#!/bin/sh
syncthing -gui-address "0.0.0.0:${SYNCTHING_PORT}" -audit -home="${SYNCTHING_CONF_DIR}" -no-browser -logfile="${SYNCTHING_CONF_DIR}/syncthing.log"
