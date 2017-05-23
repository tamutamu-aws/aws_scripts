#!/bin/bash
set -euo pipefail

echo "Install Oracle11g." 
CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


### unzip installer ###
install_zip_dir_path="${INSTALL_ZIP_LOC}"
find "${install_zip_dir_path}" -name *.zip | xargs -n1 unzip -q -d /tmp/


### Oracle11g Install ###
export ORACLE_BASE=/opt/oracle11g/app/oracle
export ORACLE_HOME="${ORACLE_BASE}"/product/11.2.0/dbhome_1
export ORACLE_INST=/opt/oracle11g


# Dependency library
yum -y --enablerepo=base install gcc libaio-devel compat-libstdc++-33 elfutils-libelf-devel mksh gcc-c++ libstc++-devel


# 11gR2 preinstall
wget https://public-yum.oracle.com/public-yum-ol6.repo --no-check-certificate -P /etc/yum.repos.d/
wget https://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol6 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle --no-check-certificate
LANG=C yum -y install oracle-rdbms-server-11gR2-preinstall
yum -y install unixODBC-devel unixODBC elfutils-libelf-devel

echo "oracle:"${ORACLE_PASS}"" | chpasswd


# Oracle Install
mkdir "${ORACLE_INST}"
chown oracle:oinstall "${ORACLE_INST}"


sed -e "s@#ORACLE_INST#@"${ORACLE_INST}"@g" \
    -e "s@#ORACLE_BASE#@"${ORACLE_BASE}"@g" \
    -e "s@#ORACLE_HOME#@"${ORACLE_HOME}"@g" \
 "${CURDIR}"/conf/ora_install.rsp.tmpl > "${ORACLE_INST}"/ora_install.rsp

su - oracle -c "/tmp/database/runInstaller -ignoreSysPrereqs -ignorePrereq -waitforcompletion  -silent -responseFile "${ORACLE_INST}"/ora_install.rsp"

su - root -c ""${ORACLE_INST}"/oraInventory/orainstRoot.sh"
su - root -c ""${ORACLE_HOME}"/root.sh -silent"


# Service
cp "${CURDIR}"/conf/oracle11g /etc/init.d
chmod a+x /etc/init.d/oracle11g
systemctl enable oracle11g
systemctl start oracle11g


# Setup Oracle env
cat << EOT > /etc/profile.d/oracle.sh
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${DB_NAME}
export PATH=\$ORACLE_HOME/bin:\$PATH
EOT

. /etc/profile.d/oracle.sh

 
# Create Database.
sed -e "s@#SYS_PASS#@"${SYS_PASS}"@g" \
    -e "s@#SYSTEM_PASS#@"${SYSTEM_PASS}"@g" \
    -e "s@#SYSMAN_PASS#@"${SYSMAN_PASS}"@g" \
    -e "s@#DBSNMP_PASS#@"${DBSNMP_PASS}"@g" \
    -e "s@#DB_NAME#@"${DB_NAME}"@g" \
 "${CURDIR}"/conf/dbca.rsp.tmpl > "${ORACLE_INST}"/dbca.rsp

su - oracle -c ". /etc/profile.d/oracle.sh && dbca -silent -responseFile "${ORACLE_INST}"/dbca.rsp" 


# Create general db user.
sqlplus system/"${SYSTEM_PASS}" << EOF
CREATE USER ${DB_USER} IDENTIFIED BY "${DB_USER_PASS}" DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp;
GRANT UNLIMITED TABLESPACE, DATAPUMP_EXP_FULL_DATABASE, DATAPUMP_IMP_FULL_DATABASE TO ${DB_USER};
exit
EOF


# Auto Start Database.
#echo "${ORACLE_SID}":"${ORACLE_HOME}:Y" >> /etc/oratab
sed -i -e "s/dbhome_1:N/dbhome_1:Y/" /etc/oratab


### Clean up
rm -rf /tmp/database/


