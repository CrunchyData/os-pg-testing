#!/bin/bash -x

# Copyright 2015 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# start pg, will initdb if /pgdata is empty as a way to bootstrap
#

source /opt/cpm/bin/setenv.sh

function initialize_replica() {
cd /tmp  
cat >> ".pgpass" <<-EOF
*:*:*:*:${PG_MASTER_PASSWORD}
EOF
chmod 0600 .pgpass
export PGPASSFILE=/tmp/.pgpass
rm -rf $PGDATA/*
chmod 0700 $PGDATA

echo "sleeping 30 seconds to give the master time to start up before performing the initial backup...."
sleep 30

pg_basebackup -x --no-password --pgdata $PGDATA --host=$PG_MASTER_HOST --port=5432 -U $PG_MASTER_USER

# PostgreSQL recovery configuration.
cp /opt/cpm/conf/pgrepl-recovery.conf /tmp
sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/pgrepl-recovery.conf
sed -i "s/PG_MASTER_HOST/$PG_MASTER_HOST/g" /tmp/pgrepl-recovery.conf
cp /opt/cpm/conf/pgrepl-recovery.conf $PGDATA/recovery.conf
}

#
# the initial start of postgres will create the database
#
function initialize_master() {
if [ ! -f /pgdata/$(hostname)/postgresql.conf ]; then
        echo "pgdata is empty and id is..."
	id
	mkdir -p $PGDATA
	initdb -D $PGDATA  > /tmp/initdb.log &> /tmp/initdb.err

	echo "overlay pg config with your settings...."
	cp /opt/cpm/conf/postgresql.conf $PGDATA
	cp /opt/cpm/conf/pg_hba.conf /tmp
	sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/pg_hba.conf
	cp /tmp/pg_hba.conf $PGDATA

        echo "starting db" >> /tmp/start-db.log

	pg_ctl -D /pgdata/$(hostname) start
        sleep 3

        echo "loading setup.sql" >> /tmp/start-db.log
	cp /opt/cpm/bin/setup.sql /tmp
	sed -i "s/PG_MASTER_USER/$PG_MASTER_USER/g" /tmp/setup.sql
	sed -i "s/PG_MASTER_PASSWORD/$PG_MASTER_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_USER/$PG_USER/g" /tmp/setup.sql
	sed -i "s/PG_PASSWORD/$PG_PASSWORD/g" /tmp/setup.sql
	sed -i "s/PG_DATABASE/$PG_DATABASE/g" /tmp/setup.sql
	sed -i "s/PG_ROOT_PASSWORD/$PG_ROOT_PASSWORD/g" /tmp/setup.sql

        psql -U postgres < /tmp/setup.sql
        exit
fi
}

function initialize_standalone() {
if [ ! -f /pgdata/postgresql.conf ]; then
	mkdir -p $PGDATA
	echo "pgdata is empty"
	initdb -D $PGDATA  > /tmp/initdb.log &> /tmp/initdb.err
	echo "overlay pg config with your settings...."
	cp /opt/cpm/conf/postgresql.conf $PGDATA
	cp /opt/cpm/conf/pg_hba.conf.standalone $PGDATA/pg_hba.conf
	echo "starting db" >> /tmp/start-db.log
	pg_ctl -D $PGDATA start
	sleep 3
	echo "loading setup.sql" >> /tmp/start-db.log
	cp /opt/cpm/bin/setup.sql.standalone /tmp
	sed -i "s/CRUNCHY_USER/$CRUNCHY_USER/g" /tmp/setup.sql.standalone
	sed -i "s/CRUNCHY_PSW/$CRUNCHY_PSW/g" /tmp/setup.sql.standalone
	sed -i "s/CRUNCHY_DB/$CRUNCHY_DB/g" /tmp/setup.sql.standalone
	psql -U postgres < /tmp/setup.sql.standalone
	exit
fi
}

#
# clean up any old pid file that might have remained
# during a bad shutdown of the container/postgres
#
rm /pgdata/postmaster.pid
#
# the normal startup of pg
#
export USER_ID=$(id -u)
cp /opt/cpm/conf/passwd /tmp
sed -i "s/USERID/$USER_ID/g" /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD=/tmp/passwd  NSS_WRAPPER_GROUP=/etc/group
echo "user id is..."
id

if [ -n "$PG_REPLICA" ]; then
	echo "working on replica..."
	initialize_replica
	pg_ctl -D $PGDATA start 
	exit
fi

if [ -n "$PG_MASTER_USER" ]; then
	echo "working on master..."
	initialize_master
	pg_ctl -D $PGDATA start 
	exit
fi

echo "working on standalone"
initialize_standalone
pg_ctl -D $PGDATA start 

