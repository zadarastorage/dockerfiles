# Grafana Metering Dashboard

## Introduction

The scripts provided in this directory will use ```docker-compose``` to
launch containers for InfluxDB and Grafana, import the VPSA's metering
data, and inject the Grafana dashboard.

This is early alpha quality, and does not cover all relevant metering
information yet.  It is offered without warranty.

## Launching

To run, you must have docker and docker-compose running on your local
system.  This currently only supports accessing various ports via
```localhost```.  It is recommended you run this on a machine with at
least 2GB memory - 4GB is ideal.

To launch, first copy the metering zip file downloaded from the VPSA
into this directory, then run:

```
./run.sh
```

## Using

To access, open Grafana:

http://localhost:3000/

And use the username ```admin``` and the password ```zadara```

Finally, open the VPSA Dashboard

## Deleting

When you are done analyzing the data, you can delete all containers and
metering data by running:

```
./down.sh
```
