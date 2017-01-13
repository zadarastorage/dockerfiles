#!/bin/sh

docker-compose down

rm -f metering*
for vpsadir in $(ls -1d */); do
  rm -rf ${vpsadir}
done
