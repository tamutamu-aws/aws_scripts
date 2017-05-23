#!/bin/bash
set -euo pipefail

echo "Install WebLogic 12c. QuickInstaller." 
echo "Deprecated!!" 

echo "Continue? [yes/no]"
read answer

case $answer in
    yes)
        echo "Continue.."
        ;;
    no)
        exit 1 
        ;;
    *)
        exit 1 
        ;;
esac


CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


### unzip installer ###
install_zip_dir_path="${INSTALL_ZIP_LOC}"
mkdir /tmp/weblogic-12c
find "${install_zip_dir_path}" -name '*quick_Disk*.zip' | xargs -n1 unzip -q -d /tmp/weblogic-12c


# If it doesn't exists user, useradd.
set +e
id "${INSTALL_USER}" > /dev/null 2>&1
is_user_exist=$?
set -e

if [ ${is_user_exist} -eq 1 ]; then
  useradd "${INSTALL_USER}"
  echo "${INSTALL_USER}:${INSTALL_USER_PASS}" | chpasswd
fi


### Install
mkdir -p /opt/weblogic-12c/home
mkdir -p /opt/weblogic-12c/oraInventory
chown -R "${INSTALL_USER}":"${INSTALL_USER}" /opt/weblogic-12c/ /tmp/weblogic-12c/

su - "${INSTALL_USER}" -c "cd /tmp/weblogic-12c && \
                           java -jar fmw_12.2.1.2.0_wls_quick.jar ORACLE_HOME=/opt/weblogic-12c/home \
                                                                  INVENTORY_LOCATION=/opt/weblogic-12c/oraInventory"


### Create Domain.
set +u
. /opt/weblogic-12c/home/wlserver/server/bin/setWLSEnv.sh
set -u

export CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom
mkdir -p /opt/weblogic-12c/home/domain/"${DOMAIN}"
cd /opt/weblogic-12c/home/domain/"${DOMAIN}"

java -Djava.security.egd=file:/dev/./urandom \
     -Dweblogic.management.GenerateDefaultConfig=true \
     -Dweblogic.Domain="${DOMAIN}" \
     -Dweblogic.management.username=${INSTALL_USER} \
     -Dweblogic.management.password=${INSTALL_USER_PASS} \
 weblogic.Server 

