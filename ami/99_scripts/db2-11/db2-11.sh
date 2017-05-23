#!/bin/bash
set -euo pipefail

echo "Install DB2 v11." 
CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


### unzip installer ###
install_zip_dir_path="${INSTALL_ZIP_LOC}"
tar -zxf "$install_zip_dir_path"/*expc*.gz -C /tmp/
tar -zxf "$install_zip_dir_path"/*nlpack*.gz -C /tmp/expc


### DB2 Install
cp $CURDIR/conf/db2expc.rsp /tmp/expc/
pushd /tmp/expc/
./db2setup -r db2expc.rsp -f nobackup
popd


### Create Database
# If it doesn't exists user, useradd.
set +e
id "${DB_USER}" > /dev/null 2>&1
is_user_exist=$?
set -e

if [ ${is_user_exist} -eq 1 ]; then
  useradd "${DB_USER}"
  echo "${DB_USER}:"${DB_USER_PASS}"" | chpasswd
fi


sed -e "s@#DB_NAME#@"${DB_NAME}"@g" \
    -e "s@#DB_USER#@"${DB_USER}"@g" \
 "${CURDIR}"/conf/createdb.sql.tmpl > "${CURDIR}"/conf/createdb.sql

su - db2inst1 -c "db2 -tvf $CURDIR/conf/createdb.sql"
rm -f "${CURDIR}"/conf/createdb.sql


### Service
su - db2inst1 -c "db2iauto -on db2inst1 && \
                  db2fm -i db2inst1 -U && \
                  db2fm -i db2inst1 -u && \
                  db2fm -i db2inst1 -f on"


### Setting path.
cat << EOT >> /home/"${DB_USER}"/.bashrc
if [ -f /home/db2inst1/sqllib/db2profile ]; then
    . /home/db2inst1/sqllib/db2profile
fi
EOT

