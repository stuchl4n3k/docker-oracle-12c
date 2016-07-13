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

## Step 1: Host prerequisites

I used Ubuntu 14.04 as a host, so it doesn't have to be an Oracle-approved
OS. You need at least 3 GB of swap space on the host. Don't think you know
better, Oracle will check during installation and just stop if you don't
have enough swap space.

You also need to set some kernel parameters and security limits. Check
[this guide](http://gemsofprogramming.wordpress.com/2013/09/19/installing-oracle-12c-on-ubuntu-12-04-64-bit-a-hard-journey-but-its-worth-it/)
and follow the parts about editing `sysctl.conf` and `limits.conf`.

**A note about shared memory:**

Oracle requires a shared memory (shm) of at least 256 MB during installation.
In the current version of Docker, this defaults to 64 MB. Docker
now supports `--shm-size` parameter to configure the shm size. That's why 
the supplied `build.sh` and `run.sh` scripts both automatically append 
`--shm-size=256m` to all docker commands.

## Step 2: Download

Either [download this repository](https://git.homecredit.net/stuchlik/docker-oracle-12c/repository/archive.zip?ref=master) or use git clone:

`$ git clone git@git.homecredit.net:stuchlik/docker-oracle-12c.git && cd docker-oracle-12c`

Then download Oracle 12c (12.1.0.2.0) [from OTN](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) 
and **extract the two zip files** in the `resources` directory, so the installer will be at `resources/database/runInstaller`.

## Step 3: Build the image

Customize the configuration in `bin/config.sh` according to your needs.

Run

```
$ bin/build.sh
```

to build the image and tag it as `oracle12c`. The script will also install 
Oracle 12c software and initialize an empty database.

It may take a while, so please be patient. Make sure you see the text 
`Successfully Setup Software.` somewhere in the output.

## Step 4: Initialize the database

Run

```
$ bin/init.sh
```

The script will prepare a datastore for your tablespace files and create
a new database `${DB_SID}`.

## Step 5: Run the database server

Run

```
$ bin/run.sh
```

The script will start the container as a daemon. If you can connect
to your database using `system/password@localhost:${DB_PORT}/${DB_SID}`,
you are finished.

## More

To start and stop container db-FOO:

```
$ docker start db-FOO
```

```
$ docker stop db-FOO
```

To start interactive shell in the running container db-FOO:

```
$ docker exec -it db-FOO /bin/bash
```

To run the container db-FOO manually (without using the provided `run.sh` script):

```
docker run --shm-size=256m -d \
    -e COMMAND=rundb -e ORACLE_SID=FOO \
    -v /tmp/db-FOO:/mnt/database \
    -p 1521:1521 \
    --name db-FOO \
    oracle12c
```

To start sqlplus as sys in the database, and shut it down afterwards:

```
$ docker run --shm-size=256m -it \
    -e COMMAND=sqlpluslocal -e ORACLE_SID=FOO \
    -v /tmp/db-FOO:/mnt/database \
    oracle12c
```

To run all `*.sql` scripts in `/tmp/sql` in the database, and shut it down afterwards:

```
$ docker run --shm-size=256m \
    -e COMMAND=runsqllocal -e ORACLE_SID=FOO \
    -v /tmp/db-FOO:/mnt/database -v /tmp/sql:/mnt/sql \
    oracle12c
```

To connect to the database FOO running in container db-FOO with sqlplus 
(using a different docker instance):

```
$ docker run --shm-size=256m -it \
    -e COMMAND=sqlplusremote -e ORACLE_SID=FOO \
    -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
    --link db-FOO:remotedb -P \
    oracle12c
```

To execute an SQL command in database FOO running in container db-FOO with
sqlplus (using a different docker instance):

```
echo "SELECT COUNT(*) FROM EMPLOYEES;" | docker run --shm-size=256m -i \
                -e COMMAND=sqlplusremote -e ORACLE_SID=FOO \
                -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
                --link db-FOO:remotedb -P oracle12c
```

To run all `*.sql` scripts in `/tmp/sql` in the database FOO running 
in container db-FOO (using a different docker instance):

```
$ docker run --shm-size=256m \
    -e COMMAND=runsqlremote -e ORACLE_SID=FOO \
    -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
    --link db-FOO:remotedb \
    -v /tmp/sql:/mnt/sql \
    oracle12c
```

You can add `-e AS_SYSDBA=true` in previous commands to connect to db-FOO
with sysdba role.

## Remarks

This docker container is a fork of **[docker-oracle-12c](https://github.com/rhopman/docker-oracle-12c/tree/e7436f378f32b8f47960e50f98b2c6158d0f230d)** by Ralph Hopman <rhopman@bol.com>. 
You can find his repo on Github.
