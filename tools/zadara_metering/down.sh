#!/bin/sh

docker-compose -p zadara_metering down

rm -f metering*
for vpsadir in $(ls -1d */); do
  rm -rf ${vpsadir}
done
