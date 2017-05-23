#!/bin/bash
set -euo pipefail

echo "Install Artifactory-5.1.0." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


cd /tmp
curl -L -o jfrog-artifactory-oss-5.1.0.zip 'https://api.bintray.com/content/jfrog/artifactory/jfrog-artifactory-oss-5.1.0.zip;bt_package=jfrog-artifactory-oss-zip'
unzip -q jfrog-artifactory-oss-5.1.0.zip
mv artifactory-oss-5.1.0/webapps/artifactory.war $TOMCAT_HOME/webapps/


###sleep 15
###st=-1
###retry=0
###max=10
###while [ $st -ne 200 ]
###do
###  if wget http://localhost:8080/artifactory --no-check-certificate 2>&1 | grep --quiet "200 OK" ; then
###     st=200
###     echo "ok"
###  else
###     retry=`expr $retry + 1`
###     sleep 5
###  fi
### 
###  if [ $retry -eq $max ]; then
###    exit 1
###  fi
###done
### Restore Settings.
###cd $CURDIR/conf
###mkdir /tmp/artifactory_imp
###unzip -q settings.zip -d /tmp/artifactory_imp/
###curl -X POST -u admin:password http://localhost:8080/artifactory/api/import/system -d "@import-settings.json" -k -H "Content-Type: application/json"


### Apache Proxy.
cp $CURDIR/conf/artifactory_proxy.conf /etc/httpd/conf.d/
