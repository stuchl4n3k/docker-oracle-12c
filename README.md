Oracle 12c in Docker
====================

Use this software to run Oracle 12c within a Docker container, while the
database files are on a mounted volume. This allows you to mount multiple
snapshots of the same volume and mount them in different containers
simultaneously.

I would recommend running this on a dedicated server (cluster) or VM,
since you will need to set some specific kernel parameters and use a
modified version of Docker. This README walks you through all the steps
to get it running.

I've only tried this with 12c so far, but I don't see any reason why it
wouldn't work with older versions of Oracle.

## A. Building this image

### Step 1: Host prerequisites

I used Ubuntu 14.04 as a host, so it doesn't have to be an Oracle-approved
OS. You need at least 3 GB of swap space on the host. Don't think you know
better, Oracle will check during installation and just stop if you don't
have enough swap space.

You also need to set some kernel parameters and security limits. Check
[this guide](http://gemsofprogramming.wordpress.com/2013/09/19/installing-oracle-12c-on-ubuntu-12-04-64-bit-a-hard-journey-but-its-worth-it/)
and follow the parts about editing `sysctl.conf` and `limits.conf`.

**A note about shared memory:**

Oracle requires a shared memory (shm) of at least 256 MB during installation.
In the current version of Docker, this defaults to 64 MB. That's why 
you should append `--shm-size=256m` to docker run and build commands.

### Step 2: Download

Either [download this repository](https://git.homecredit.net/stuchlik/docker-oracle-12c/repository/archive.zip?ref=master) or use git clone:

`$ git clone git@git.homecredit.net:stuchlik/docker-oracle-12c.git && cd docker-oracle-12c`

Then download Oracle 12c (12.1.0.2.0) [from OTN](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) 
and **extract the two zip files** in the `resources` directory, so the installer will be at `resources/database/runInstaller`.

### Step 3: Build the image

Run

```bash
docker build --shm-size=256m -t embedit/oracle .
```

to build the image and tag it as `embedit/oracle`. The build will install 
Oracle 12c software, which may take a while, so please be patient. 
Make sure you see the text `Successfully Setup Software.` somewhere 
in the output.

## B. Running the database

To run a container use:

```bash
docker run --shm-size=256m -it \
    -e COMMAND=rundb -e ORACLE_SID=FOO \
    -p 1521:1521 \
    --name db-FOO embedit/oracle
```

This will run a docker container and name it `db-FOO`.

If no database exists in `/mnt/database`, then first time initialization 
will take place: datastore for your tablespace files will be prepared
and a new database `FOO` will be created and exposed on port `1521`.

The database creation takes a while, so please be patient.

After the listener has been started you should be able to connect to the database using 
`system/password@localhost:1521/FOO`.

## Control variables

The entrypoint script (`/home/oracle/bin/start.sh`) is controlled by environment variables listed below.

```
# Mandatory variable that controls what to do in entrypoint script after you `docker run`.
# Must be one of {initdb|rundb|runsqlplus|runsql}
COMMAND=rundb

# Mandatory variable that controls which SID is initialized and run.
ORACLE_SID=db-FOO

# DB login credentials, needed only when running sqlplus or a batch of sql scripts.
ORACLE_USER=system
ORACLE_PASSWORD=password

# Optional variable that can be used to run sqlplus or batch of sql scripts as `sysdba` role if set to true.
AS_SYSDBA=true
```

## More

To start and stop container `db-FOO`:

```bash
docker start db-FOO
```

```bash
docker stop db-FOO
```

To invoke interactive shell in the running container `db-FOO`:

```bash
docker exec -it db-FOO /bin/bash
```

To connect to the database `FOO` running in container `db-FOO` with builtin
sqlplus (using a different docker instance):

```bash
docker run -it \
    -e COMMAND=runsqlplus -e ORACLE_SID=FOO \
    -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
    --link db-FOO:remotedb -P \
    embedit/oracle
```

To execute an SQL command in database `FOO` running in container `db-FOO` with
builtin sqlplus (using a different docker instance):

```bash
echo "SELECT COUNT(*) FROM EMPLOYEES;" | docker run --shm-size=256m -i \
                -e COMMAND=runsqlplus -e ORACLE_SID=FOO \
                -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
                --link db-FOO:remotedb -P embedit/oracle
```

To run all `*.sql` scripts in `/tmp/sql` in the database `FOO` running 
in container `db-FOO` with builtin sqlplus (using a different docker instance):

```bash
docker run --shm-size=256m \
    -e COMMAND=runsql -e ORACLE_SID=FOO \
    -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
    -v /tmp/sql:/mnt/sql
    --link db-FOO:remotedb \
    embedit/oracle
```

You can add `-e AS_SYSDBA=true` in previous commands to connect to db-FOO
with sysdba role.

To use persistent datastore, map `/mnt/database` to a directory in your host
on container startup:

```bash
mkdir -p ~/oradb/db-FOO/tablespaces
chmod -R 777 ~/oradb/db-FOO
docker run --shm-size=256m -d \
    -v ~/oradb/db-FOO:/mnt/database \
    -e COMMAND=rundb -e ORACLE_SID=FOO \
    -p 1521:1521 \
    --name db-FOO embedit/oracle
```

## Remarks

* This docker project is a fork of **[docker-oracle-12c](https://github.com/rhopman/docker-oracle-12c)** by Ralph Hopman <rhopman@bol.com>. 
You can find his repo on Github.
