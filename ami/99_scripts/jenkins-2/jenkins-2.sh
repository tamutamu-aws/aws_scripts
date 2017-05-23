#!/bin/bash
set -euo pipefail

echo "Install Jenkins2." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


### Install
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war -P "${TOMCAT_HOME}"/webapps/


### Apache Proxy
cp "${CURDIR}"/conf/jenkins2_proxy.conf /etc/httpd/conf.d/


### Configure Service
cp /etc/sysconfig/tomcat8{,.orig}
gawk -f add_env2service.awk /etc/sysconfig/tomcat8.orig \
  > /etc/sysconfig/tomcat8


### Create backup directory
mkdir /var/backup/jenkins2
chown tomcat:tomcat /var/backup/jenkins2


### Restore Setting Confgiure
systemctl stop tomcat8.service
rm -rf "${TOMCAT_HOME}"/.jenkins
mkdir "${TOMCAT_HOME}"/.jenkins
tar xzf "${CURDIR}"/conf/jenkins_backup.tar.gz --strip-components=1 -C "${TOMCAT_HOME}"/.jenkins/
chown tomcat:tomcat /opt/tomcat8/.jenkins -R

systemctl daemon-reload

systemctl restart tomcat8.service
systemctl restart httpd.service
