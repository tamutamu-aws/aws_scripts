#!/bin/bash
set -euo pipefail

echo "Install Postgresql 9.6." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


pushd /tmp

### Install
yum -y localinstall https://yum.postgresql.org/9.6/redhat/rhel-6.7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
yum --disablerepo="*" --enablerepo="pgdg96" -y install postgresql96-server

### Setup
/usr/pgsql-9.6/bin/postgresql96-setup initdb

systemctl enable postgresql-9.6
systemctl start postgresql-9.6

### Set postgres user password.
sudo -u postgres psql -U postgres -c "ALTER USER postgres with encrypted password '$POSTGRES_PASS';"


### Create database for develop
sed -e "s/#DB_NAME#/"${DB_NAME}"/" \
    -e "s/#DB_USER#/"${DB_USER}"/" \
    -e "s/#DB_USER_PASS#/"${DB_USER_PASS}"/" \
 $CURDIR/conf/createdb.sql.tmpl > $CURDIR/conf/createdb.sql

sudo -u postgres psql -U postgres < $CURDIR/conf/createdb.sql
rm -f $CURDIR/conf/createdb.sql


### Disable peer. Change md5 for host,local
sed -i.bak -e 's/^host/#host/g' -e 's/^local/#local/' /var/lib/pgsql/9.6/data/pg_hba.conf

echo "host    all    all       0.0.0.0/0            md5" >> /var/lib/pgsql/9.6/data/pg_hba.conf
echo "local   all    all                            md5" >> /var/lib/pgsql/9.6/data/pg_hba.conf

echo "listen_addresses='*'" >> /var/lib/pgsql/9.6/data/postgresql.conf

systemctl restart postgresql-9.6

