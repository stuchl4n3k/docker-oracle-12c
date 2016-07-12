#!/bin/bash
set -e

DIR=$(dirname "$(readlink -f $0)")
ROOT_DIR=$(dirname "$DIR")

. ${DIR}/config.sh

# Run Oracle DB
docker run --shm-size=256m -d \
    -e COMMAND=rundb -e ORACLE_SID=${DB_SID} \
    -v ${DATASTORE_PATH}:/mnt/database \
    -p ${DB_PORT}:1521 \
    --name ${DOCKER_INSTANCE} oracle12c

if [ ${UNLOCK_SYSDBA} ]; then
	# Allow remote login using to Oracle DB using sysdba role.
	docker exec ${DOCKER_INSTANCE} /bin/bash -c "~/bin/unlock_sysdba.sh"
fi

# Enable Oracle Managed Files (OMF) support.
# Oracle will now store datafiles to DB_CREATE_FILE_DEST.
echo "ALTER system SET DB_CREATE_FILE_DEST = '/mnt/database/tablespaces';" | ${SQLPLUS_CMD}
