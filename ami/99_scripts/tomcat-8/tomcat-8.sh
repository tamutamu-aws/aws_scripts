#!/bin/bash
set -euo pipefail

echo "Install Tomcat8." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


pushd /tmp

### Create User "tomcat".
groupadd tomcat
useradd -M -s /bin/nologin -g tomcat -d "${TOMCAT_HOME}" tomcat
mkdir "${TOMCAT_HOME}"
chown tomcat:tomcat "${TOMCAT_HOME}"
chmod g+s "${TOMCAT_HOME}"

### Install Tomcat8
wget http://apache.mirrors.ionfish.org/tomcat/tomcat-8/v"${TOMCAT_VER}"/bin/apache-tomcat-"${TOMCAT_VER}".tar.gz
tar xf apache-tomcat-"${TOMCAT_VER}".tar.gz -C "${TOMCAT_HOME}" --strip-components=1
chown -R tomcat:tomcat "${TOMCAT_HOME}"


### Settings Manager app.
sed -i.bak -e "s#</tomcat-users>#  <user username=\""${ADMIN_USER}"\" password=\""${ADMIN_PASS}"\" roles=\"manager-gui,admin-gui\" />\n</tomcat-users>#" \
  "${TOMCAT_HOME}"/conf/tomcat-users.xml

sed -i.bak -e 's#^.*\(<Valve.*$\)#    <!-- \1#' -e 's#\(^[ ]*allow.*0:1" />\)#  \1 -->#' \
  "${TOMCAT_HOME}"/webapps/manager/META-INF/context.xml

sed -i.bak -e 's#^.*\(<Valve.*$\)#    <!-- \1#' -e 's#\(^[ ]*allow.*0:1" />\)#  \1 -->#' \
  "${TOMCAT_HOME}"/webapps/host-manager/META-INF/context.xml


### Install Service
cp "${CURDIR}"/conf/tomcat8.service /etc/systemd/system/
cp "${CURDIR}"/conf/tomcat8 /etc/sysconfig/
mkdir /etc/systemd/system/tomcat8.service.d/

systemctl enable tomcat8.service
systemctl start tomcat8.service


### Apache proxy
cp "${CURDIR}"/conf/tomcat8_proxy.conf /etc/httpd/conf.d/

popd
