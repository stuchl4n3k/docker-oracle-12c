#!/bin/bash
set -e

DIR=$(dirname "$(readlink -f $0)")
ROOT_DIR=$(dirname "$DIR")

. ${DIR}/config.sh

if [ ! -f "${ROOT_DIR}/resources/database/runInstaller" ]; then
    echo "Error: Oracle database installer not found.";
    echo "Download and extract it to resources dir, so that the installer can be located at 'resources/database/runInstaller'";
    exit 1
fi

# Build Oracle 12c Docker image
docker build --shm-size=256m \
    -t oracle12c ${ROOT_DIR}

# Init Oracle DB
mkdir -p ${DATASTORE_PATH}/tablespaces
chmod -R 777 ${DATASTORE_PATH}

docker run --shm-size=256m \
    -e COMMAND=initdb -e ORACLE_SID=${DB_SID} \
    -v ${DATASTORE_PATH}:/mnt/database \
    oracle12c