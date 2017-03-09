#!/usr/bin/ienv bash

echo "Starting Grafana and InfluxDB instances"
#docker run --restart always --name=influxdb -d -p 8083:8083 -p 8086:8086 -v influxdb:/var/lib/influxdb zadara/capmon
#docker run --restart always -d -p 3000:3000 --name grafana -e "GF_SERVER_ROOT_URL=http://localhost" -e "GF_SECURITY_ADMIN_PASSWORD=zadara" zadara/capmon

#service influxdb start
#service grafana-server start

service ssh start
