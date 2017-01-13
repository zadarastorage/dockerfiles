#!/bin/sh

CreateInfluxDB() {
  echo "Creating Influx database..."
  curl -s -X POST 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE VPSA1"
}

InjectInfluxData() {
  echo "Injecting data into Influx database..."
  for vpsadir in $(ls -1d */); do
    vpsa=${vpsadir%?}
    for influxfile in $(ls -1 ${vpsa}/*.influx); do
      echo "Injecting ${influxfile}"
      docker run --network=zadarametering_default --rm -v $PWD/${influxfile}:/metering.txt influxdb influx -host influxdb -database 'VPSA1' -import -path=/metering.txt -precision='s'
    done
  done
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

ExtractAllMeteringFiles() {
  echo "Unzipping metering information..."
  for meteringpackage in $(ls -1 metering*.zip); do
    targetfile=$(echo ${meteringpackage} | sed -e 's#^metering_\(.*\)_\(20[0-9]\)\(.*\).zip#\2\3#g' )
    targetfolder=$(echo ${meteringpackage} | sed -e 's#^metering_\(.*\)_'${targetfile}'.zip#\1#g' )
    echo "  Extracting ${meteringpackage} to ${targetfolder}/${targetfile}..."
    mkdir -p ${targetfolder}
    unzip -p ${meteringpackage} metering > ${targetfolder}/${targetfile}
  done
}

ConvertMeteringFiles() {
  echo "Converting metering to influx format..."
  for vpsadir in $(ls -1d */); do
    vpsa=${vpsadir%?}
    for meterdb in $(ls -1 ${vpsadir}); do
      echo "  Converting ${meterdb} for ${vpsa}"
      ./meter2influx.py ${vpsadir}${meterdb} --all --output_type INFLUXDB --cloud_id vpsa_metering --tsdb_id VPSA1 --vpsa_id ${vpsa} > ${vpsa}/${meterdb}.influx
    done
  done
}

ExtractAllMeteringFiles
ConvertMeteringFiles

# Bring up containers
echo "Bringing up containers..."
docker-compose up -d

echo "Waiting for containers..."
sleep 30

CreateInfluxDB
InjectInfluxData
AddDataSource
AddDashboard
