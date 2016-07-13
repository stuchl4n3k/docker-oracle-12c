#!/bin/bash
set -e

DIR=$(dirname "$(readlink -f $0)")
ROOT_DIR=$(dirname "$DIR")

. ${DIR}/config.sh

# Init Oracle DB
mkdir -p ${DATASTORE_PATH}/tablespaces
chmod -R 775 ${DATASTORE_PATH}

docker run --shm-size=256m \
    -e COMMAND=initdb -e ORACLE_SID=${DB_SID} \
    -v ${DATASTORE_PATH}:/mnt/database \
    oracle12c
