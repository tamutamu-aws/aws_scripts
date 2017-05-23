#!/bin/bash
set -euo pipefail

echo "Install WebLogic 12c." 
CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


### unzip installer ###
install_zip_dir_path="${INSTALL_ZIP_LOC}"
mkdir /tmp/weblogic-12c
find "${install_zip_dir_path}" -name '*wls_Disk1*.zip' | xargs -n1 unzip -q -d /tmp/weblogic-12c


# If it doesn't exists user, useradd.
set +e
id "${INSTALL_USER}" > /dev/null 2>&1
is_user_exist=$?
set -e

if [ ${is_user_exist} -eq 1 ]; then
  useradd "${INSTALL_USER}"
  echo "${INSTALL_USER}:"${INSTALL_USER_PASS}"" | chpasswd
fi


### Install
cp $CURDIR/conf/weblogic-12c.rsp /tmp/weblogic-12c/
sed -e "s@#INSTALL_GROUP#@"${INSTALL_USER}"@g" \
 "${CURDIR}"/conf/oraInst.loc.tmpl > /tmp/weblogic-12c/oraInst.loc


mkdir -p /opt/weblogic-12c/oraInventory
chown -R "${INSTALL_USER}":"${INSTALL_USER}" /opt/weblogic-12c/ /tmp/weblogic-12c/

su - "${INSTALL_USER}" -c "cd /tmp/weblogic-12c && \
                           export CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom && \
                           java -jar fmw_12.2.1.2.0_wls.jar -silent \
                                -invPtrLoc /tmp/weblogic-12c/oraInst.loc \
                                -responseFile /tmp/weblogic-12c/weblogic-12c.rsp"

rm -f $CURDIR/conf/oraInst.loc


### Create Domain
set +u
. /opt/weblogic-12c/home/wlserver/server/bin/setWLSEnv.sh
set -u

sed -e "s@#DOMAIN#@"${DOMAIN}"@g" \
    -e "s@#USER_WEBLOGIC_PASS#@"${USER_WEBLOGIC_PASS}"@g" \
 "${CURDIR}"/conf/create_domain.py.tmpl > /tmp/weblogic-12c/create_domain.py

java -Djava.security.egd=file:/dev/./urandom weblogic.WLST /tmp/weblogic-12c/create_domain.py

chown -R "${INSTALL_USER}":"${INSTALL_USER}" /opt/weblogic-12c/ 


### Service
sed -e "s@#DOMAIN#@"${DOMAIN}"@g" \
    -e "s@#INSTALL_USER#@"${INSTALL_USER}"@g" \
 "${CURDIR}"/conf/weblogic12c.tmpl > /etc/systemd/system/weblogic12c.service

systemctl enable weblogic12c.service
systemctl start weblogic12c.service


### Apache Proxy.
mkdir -p /tmp/weblogic-12c/apache/plugins
find "${install_zip_dir_path}" -name '*_wlsplugins_Disk1*.zip' | xargs -n1 unzip -q -d /tmp/weblogic-12c/apache
find /tmp/weblogic-12c/apache/ -name '*.zip' | xargs -n1 unzip -q -d /tmp/weblogic-12c/apache/plugins
find /tmp/weblogic-12c/apache/plugins -name '*Apache*Linux*.zip' | xargs -n1 unzip -q -d /tmp/weblogic-12c/apache/plugins

cp /tmp/weblogic-12c/apache/plugins/lib/mod_wl_24.so /etc/httpd/modules/
cp /tmp/weblogic-12c/apache/plugins/lib/libopmnsecure.so /lib64/
cp /tmp/weblogic-12c/apache/plugins/lib/libonssys.so /lib64/
cp /tmp/weblogic-12c/apache/plugins/lib/libdms2.so /lib64/

cp $CURDIR/conf/weblogic.conf /etc/httpd/conf.d/
cp $CURDIR/conf/99-weblogic.conf /etc/httpd/conf.modules.d/
