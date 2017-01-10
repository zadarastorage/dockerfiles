#!/bin/sh

CreateInfluxDB() {
  echo "Creating Influx database..."
  curl -s -X POST 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE VPSA1"
}

InjectInfluxData() {
  echo "Injecting data into Influx database..."
  docker run --network=zadarametering_default --rm -v $PWD/metering.txt:/metering.txt influxdb influx -host influxdb -database 'VPSA1' -import -path=/metering.txt -precision='s'
}

AddDataSource() {
  echo "Adding Influx datasource to Grafana..."
  curl -s 'http://admin:zadara@localhost:3000/api/datasources' \
    -X POST \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary \
    '{"name":"VPSA1","type":"influxdb","url":"http://localhost:8086","access":"direct","isDefault":true,"database":"VPSA1","user":"admin","password":"zadara"}'
}

AddDashboard() {
  echo "Importing Grafana metering dashboard..."
  curl -s 'http://admin:zadara@localhost:3000/api/dashboards/import' \
    -X POST \
    -H 'Content-Type: application/json;charset=utf-8' \
    --data-binary @vpsa_statistics.json
}

echo "Unzipping metering information..."
unzip metering*.zip
rm -f meter2csv.py
echo "Converting metering to influx format..."
./meter2influx.py metering --all --output_type INFLUXDB --cloud_id vpsa_metering --tsdb_id VPSA1 --vpsa_id vpsa > metering.txt

# Bring up containers
echo "Bringing up containers..."
docker-compose up -d

echo "Waiting for containers..."
sleep 30

CreateInfluxDB
InjectInfluxData
AddDataSource
AddDashboard
