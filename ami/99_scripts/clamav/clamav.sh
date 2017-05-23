#!/bin/bash
set -euo pipefail

echo "Install ClamAV." 

CURDIR=$(cd $(dirname $0); pwd)


pushd /tmp

### Install ClamAV
yum -y install --enablerepo=epel clamav-server clamav-data clamav-update \
                              clamav-filesystem clamav clamav-scanner \
                              clamav-scanner-systemd clamav-devel \
                              clamav-lib clamav-server-systemd

### Copy Config
\cp -f "${CURDIR}"/conf/freshclam.conf /etc/
\cp -f "${CURDIR}"/conf/scan.conf /etc/clamd.d/
ln -s /etc/clamd.d/scan.conf /etc/clamd.conf


### Service
systemctl start clamd@scan.service
systemctl enable clamd@scan.service


### Cron
mkdir -p /opt/clamav
\cp -f "${CURDIR}"/conf/clamav.sh /opt/clamav/
chmod a+x /opt/clamav/clamav.sh
\cp -f "${CURDIR}"/conf/clamav /etc/cron.d/


### Proxy
if [ ! -z "${HTTP_PROXY+x}" ] ; then
  proxy_host=$(echo ${HTTP_PROXY} | cut -d ':' -f 1-2)
  proxy_port=$(echo ${HTTP_PROXY} | cut -d ':' -f 3)

cat <<EOF >> /etc/freshclam.conf
HTTPProxyServer ${proxy_host}
HTTPProxyPort ${proxy_port}
EOF

fi


### Update
freshclam -u root
