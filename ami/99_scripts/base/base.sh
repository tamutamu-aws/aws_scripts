#!/bin/bash
set -euo pipefail

echo "Install Base Settings."
CURDIR=$(cd $(dirname $0); pwd)


yum -y install epel-release
yum -y install gcc make gcc-c++ perl zip unzip bzip2 vim wget
yum -y update


### Add developer group and create utility script directory.
groupadd developer
mkdir /opt/scripts
chown -R :developer /opt/scripts
chmod 2770 /opt/scripts  #SGID


### Create Backup Directory
mkdir /var/backup/
chmod a+rwx /var/backup -R
