#!/bin/bash
set -euo pipefail

echo "Install SonarQube."

. ./var.conf
CURDIR=$(cd $(dirname $0); pwd)

pushd /tmp

wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
yum -y install sonar-6.2-1
 
## create database
sed  -e "s/#SONAR_DB#/$SONAR_DB/g" \
     -e "s/#SONAR_USER#/$SONAR_USER/g" \
     -e "s/#SONAR_PASS#/$SONAR_PASS/g" \
 $CURDIR/conf/create_db.sql.tmpl > $CURDIR/conf/create_db.sql

mysql -uroot -p$MYSQL_ROOT_PASS < $CURDIR/conf/create_db.sql
 
 
## sonar.properties
sed  -e "s/#SONAR_DB#/$SONAR_DB/g" \
     -e "s/#SONAR_USER#/$SONAR_USER/g" \
     -e "s/#SONAR_PASS#/$SONAR_PASS/g" \
 $CURDIR/conf/sonar.properties.tmpl > $CURDIR/conf/sonar.properties
\cp -f $CURDIR/conf/sonar.properties /opt/sonar/conf/ 


## Settings service
chkconfig sonar on
service sonar start
 

## apache proxy
cp $CURDIR/conf/sonar_proxy.conf /etc/httpd/conf.d/
systemctl restart httpd.service 
 
popd
