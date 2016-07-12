#!/bin/bash

## 
# Oracle database instance SID
#
DB_SID=FOO

## 
# Exposed DB port in host
#
DB_PORT=1521

##
# Docker container name
#
DOCKER_INSTANCE=db-${DB_SID}

##
# Path on host where to store Oracle datafiles
#
DATASTORE_PATH=~/oradb/${DOCKER_INSTANCE}


##
# Whether to allow sysdba remote connection for user system
#
UNLOCK_SYSDBA=true

##
# Command to run SQLPlus
# You can use your local sqlplus if you have it installed
#
SQLPLUS_CMD="docker run --shm-size=256m -i \
                -e COMMAND=sqlplusremote -e ORACLE_SID=${DB_SID} \
                -e ORACLE_USER=system -e ORACLE_PASSWORD=password -e AS_SYSDBA=true \
                --link ${DOCKER_INSTANCE}:remotedb -P oracle12c"
