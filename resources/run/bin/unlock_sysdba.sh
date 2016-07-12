#!/bin/bash

orapwd file=${ORACLE_HOME}/dbs/orapw${DB_SID} password=password
sqlplus / as sysdba @/home/oracle/grant_sysdba_to_system.sql

