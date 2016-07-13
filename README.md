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
docker build --shm-size=256m -t stuchl4n3k/o12c .
```

to build the image and tag it as `stuchl4n3k/o12c`. The build will install 
Oracle 12c software, which may take a while, so please be patient. 
Make sure you see the text `Successfully Setup Software.` somewhere 
in the output.

## B. Running the database

Run

```bash
docker run --shm-size=256m -d \
    -e COMMAND=rundb -e ORACLE_SID=FOO \
    -p 1521:1521 \
    --name db-FOO stuchl4n3k/o12c
```

This will run a docker container as a daemon and name it `db-FOO`.
It will also prepare a datastore for your tablespace files and create
a new database `FOO` on exposed port 1521 (if no such DB already exists
in `/mnt/database`).

You should be now able to connect to your database using 
`system/password@localhost:1521/FOO`.

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
    stuchl4n3k/o12c
```

To execute an SQL command in database `FOO` running in container `db-FOO` with
builtin sqlplus (using a different docker instance):

```bash
echo "SELECT COUNT(*) FROM EMPLOYEES;" | docker run --shm-size=256m -i \
                -e COMMAND=sqlplusremote -e ORACLE_SID=FOO \
                -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
                --link db-FOO:remotedb -P oracle12c
```

To run all `*.sql` scripts in `/tmp/sql` in the database `FOO` running 
in container `db-FOO` with builtin sqlplus (using a different docker instance):

```bash
docker run --shm-size=256m \
    -e COMMAND=runsql -e ORACLE_SID=FOO \
    -e ORACLE_USER=system -e ORACLE_PASSWORD=password \
    --link db-FOO:remotedb \
    stuchl4n3k/o12c
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
    --name db-FOO stuchl4n3k/o12c
```


## Remarks

* This docker project is a fork of **[docker-oracle-12c](https://github.com/rhopman/docker-oracle-12c)** by Ralph Hopman <rhopman@bol.com>. 
You can find his repo on Github.
