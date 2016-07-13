FROM centos

MAINTAINER Petr Stuchlik <petr.stuchlik@embedit.cz>
# FORKED FROM docker-oracle-12c by Ralph Hopman <rhopman@bol.com>

# Environment
ENV ORACLE_BASE     /opt/oracle
ENV ORACLE_HOME     /opt/oracle/product/12.1.0.2/dbhome_1
ENV PATH 	        $PATH:$ORACLE_HOME/bin

# Groups
RUN groupadd oracle
RUN groupadd dba
RUN groupadd oinstall

# User oracle
RUN adduser -g oracle -G dba,oinstall oracle
RUN mkdir -p /opt/oracle/admin/orcl/adump
RUN mkdir -p /opt/oracle/fast_recovery_area
RUN chown -R oracle:oracle /opt/oracle

# Datastore directory
RUN mkdir -p /mnt/database/tablespaces
RUN chmod -R 777 /mnt/database

# Inventory directory
RUN mkdir /opt/oraInventory
RUN chown oracle:oinstall /opt/oraInventory

# Required packages
RUN yum install -y compat-libcap1 compat-libstdc++-33 libstdc++-devel gcc-c++ ksh make libaio-devel
# This one gives errors
RUN yum install -y sysstat; true

# Add database software
ADD resources/database /home/oracle/database/

# Add install-time resources
ADD resources/install /home/oracle/
RUN chmod +x /home/oracle/bin/*

# Oracle uses /usr/bin/who -r to check runlevel. Because Docker doesn't have a runlevel,
# we need to fake it.
RUN mv /usr/bin/who /usr/bin/who.orig
RUN ln -s /home/oracle/bin/who /usr/bin/who

# Install Oracle database
USER oracle
RUN /home/oracle/bin/install.sh

# Post-installation scripts
USER root
RUN /home/oracle/bin/postinstall.sh

# Add run-time resources
ADD resources/run /home/oracle/
RUN chmod +x /home/oracle/bin/*

USER oracle
VOLUME /mnt/database
EXPOSE 1521
CMD ["/home/oracle/bin/start.sh"]
