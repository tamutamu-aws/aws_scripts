#!/bin/bash
set -euo pipefail

echo "Install Mysql." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


## Install
rpm --import http://dev.mysql.com/doc/refman/5.7/en/checking-gpg-signature.html
yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
yum -y install mysql-community-server
mysqld --initialize-insecure --user=mysql
systemctl enable mysqld.service
systemctl restart mysqld.service


## Create General Database & User.
mysql -uroot <<EOF 
create database ${DB_NAME} default character set utf8;
grant all on ${DB_NAME}.* to ${DB_USER}@'%' identified by '${DB_USER_PASS}';
EOF


## Secure Settings.
sed  -e "s/#MYSQL_ROOT_PASS#/${MYSQL_ROOT_PASS}/g" \
 $CURDIR/conf/mysql_secure_installation.sql.tmpl > $CURDIR/conf/mysql_secure_installation.sql

mysql -uroot < $CURDIR/conf/mysql_secure_installation.sql
rm -f $CURDIR/conf/mysql_secure_installation.sql

