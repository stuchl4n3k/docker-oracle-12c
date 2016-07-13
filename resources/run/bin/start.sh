#!/bin/bash

echo "SPFILE='/mnt/database/dbs/spfile${ORACLE_SID}.ora'" > /opt/oracle/product/12.1.0.2/dbhome_1/dbs/init${ORACLE_SID}.ora

function startupdb {
  echo "*** Starting database ${ORACLE_SID}"
  sqlplus / as sysdba @/home/oracle/startup.sql
}

function shutdowndb {
  echo "*** Shutting down database ${ORACLE_SID}"
  sqlplus / as sysdba @/home/oracle/shutdown.sql
}

function initdb {
  # Check if database already exists
  if [ -d /mnt/database/oradata ]; then
    echo "*** Database already exists"
    exit 1
  else
    echo "*** Creating database in /mnt/database"

    # Create the database
    /opt/oracle/product/12.1.0.2/dbhome_1/bin/dbca -silent -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile /home/oracle/dbca.rsp

    shutdowndb
 fi
}

function rundb {
  # Autocreate database if it does not exist.
  if [ ! -d /mnt/database/oradata ]; then
    initdb
  fi

  # Start DB.
  startupdb

  # Allow remote login using to Oracle DB using sysdba role.
  unlocksysdba

  # Start TNS listener.
  lsnrctl start
  
  # Tail the alert log so the process will keep running.
  tail -n 1000 -f /mnt/database/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/alert/log.xml | grep --line-buffered "<txt>" | stdbuf -o0 sed 's/ <txt>//'
}

function runsqlplus {
  SQLPLUS_CMD="sqlplus ${ORACLE_USER}/${ORACLE_PASSWORD}@${REMOTEDB_PORT_1521_TCP_ADDR}:${REMOTEDB_PORT_1521_TCP_PORT}/${ORACLE_SID}"
  if [ $AS_SYSDBA ]; then
    SQLPLUS_CMD="${SQLPLUS_CMD} as sysdba"
  fi

  ${SQLPLUS_CMD}
}

function runsql {
  SQLPLUS_CMD="sqlplus -S ${ORACLE_USER}/${ORACLE_PASSWORD}@${REMOTEDB_PORT_1521_TCP_ADDR}:${REMOTEDB_PORT_1521_TCP_PORT}/${ORACLE_SID}"
  if [ $AS_SYSDBA ]; then
    SQLPLUS_CMD="${SQLPLUS_CMD} as sysdba"
  fi

  # Run all SQL scripts in /mnt/sql.
  find /mnt/sql -maxdepth 1 -type f -name *.sql | sort | while read script; do
    echo
    echo "*** Running script $script in database ${ORACLE_USER}@${REMOTEDB_PORT_1521_TCP_ADDR}:${REMOTEDB_PORT_1521_TCP_PORT}/${ORACLE_SID}"
    echo exit | ${SQLPLUS_CMD} @$(printf %q "$script");
  done
}

function unlocksysdba {
  echo "*** Unlocking SYSDBA role for user system"
  orapwd file=${ORACLE_HOME}/dbs/orapw${DB_SID} password=password
  sqlplus / as sysdba @/home/oracle/grant_sysdba_to_system.sql
}

case "$COMMAND" in
  initdb)
    initdb
    ;;
  rundb)
    rundb
    ;;
  runsqlplus)
    runsqlplus
    ;;
  runsql)
    runsql
    ;;
  *)
    echo "Environment variable COMMAND must be {initdb|sqlpluslocal|runsqllocal|rundb|runsqlplus|runsqlremote}, e.g.:"
    echo "  To initialize a database FOO in /tmp/db-FOO:"
    echo "  docker run -e COMMAND=initdb -e ORACLE_SID=FOO -v /tmp/db-FOO:/mnt/database oracle12c"
    echo ""
    echo "  To start the database:"
    echo "  docker run -d -e COMMAND=rundb -e ORACLE_SID=FOO -v /tmp/db-FOO:/mnt/database -P --name db1 oracle12c"
    echo ""
    echo "  To connect to the database FOO running in container db1 with sqlplus:"
    echo "  docker run -i -t -e COMMAND=runsqlplus -e ORACLE_SID=FOO -e ORACLE_USER=system -e ORACLE_PASSWORD=password --link db1:remotedb -P oracle12c"
    echo ""
    echo "  To run all *.sql scripts in /tmp/sql in the database FOO running in container db1:"
    echo "  docker run -e COMMAND=runsqlremote -e ORACLE_SID=FOO -e ORACLE_USER=system -e ORACLE_PASSWORD=password --link db1:remotedb -v /tmp/sql:/mnt/sql oracle12c"
    exit 1
    ;;
esac

