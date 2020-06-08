#!/bin/bash

# Check necessary env vars
EXIT=0
for var in 'DOCKER_ORG' 'CONTAINER'; do
	if [[ -z "${!var}" ]]; then
		echo "[ERROR]: ${var} was not defined"
		EXIT=1
	fi
done
if [[ ${EXIT} -eq 1 ]]; then
	exit 1
fi
OPWD=$(pwd)

# Exit function
exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

# Construct docker-compose build file from dockerfiles
cd ${CONTAINER}
COMPOSE='{"version": "3"}'
for dockerfile in $(ls -1 Dockerfile.* | sort -V); do
	TAG=${dockerfile#*.}
	COMPOSE=$(echo ${COMPOSE} | jq --arg service "${TAG}" --arg dockerfile "${dockerfile}" --arg tag "${TAG}" --arg image "${DOCKER_ORG}/${CONTAINER}:${TAG}" '.services[$service] = {build: {context: ".", dockerfile: $dockerfile}, image: $image}')
	if [[ -n "${LATEST}" && "${LATEST}" == "${TAG}" ]]; then
		COMPOSE=$(echo ${COMPOSE} | jq --arg service "latest" --arg dockerfile "${dockerfile}" --arg tag "${TAG}" --arg image "${DOCKER_ORG}/${CONTAINER}:latest" '.services[$service] = {build: {context: ".", dockerfile: $dockerfile}, image: $image}')
	fi
done
echo ${COMPOSE} | yq -y '.' > compose-build.yml
cat compose-build.yml

# Build all documented containers
docker-compose -f compose-build.yml build
exit_on_error $? !!
# Push all documented containers
docker-compose -f compose-build.yml push
exit_on_error $? !!

rm compose-build.yml
cd ${OPWD}
