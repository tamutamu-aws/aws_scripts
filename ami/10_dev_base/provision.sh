#!/bin/bash
set -euo pipefail

general_user="${1}"
source_ami_user="${2}"

### Create User Scripts Dir
mkdir /opt/scripts
chown -R :wheel /opt/scripts
chmod 2770 /opt/scripts  #SGID

### SELinux
setenforce 0
sed -i.bak -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


find ./ -name '*.sh' -type f -print | xargs chmod +x

### Common Dev Tools
(cd ./common-dev && ./common-dev.sh)


### aws
(cd ./aws && ./aws.sh)


### Clamav
(cd ./clamav && ./clamav.sh)


### Java
(cd ./java && ./jdk.sh)
(cd ./java && ./maven-3.sh)
(cd ./java && ./gradle-2.sh)


### Replace EC2 Default User.
ami_default_user=$(gawk '
  /^system_info:.*$/ {
    SYS_NR=NR
  }

  (/^[ ]*name:.*/) && (SYS_NR+2 == NR) {
    sub("name:","");
    gsub(" ","");
    print $0;
  }
' /etc/cloud/cloud.cfg)

rm -rf /var/lib/cloud/*
sed -i.bak -e "s/\(^[ ]*name:.*\)${source_ami_user}/\1${general_user}/" /etc/cloud/cloud.cfg

rm -rf /tmp/*
