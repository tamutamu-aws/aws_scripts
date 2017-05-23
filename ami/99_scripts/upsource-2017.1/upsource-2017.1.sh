#!/bin/bash
set -euo pipefail

echo "Install Upsource-2017.1." 

CURDIR=$(cd $(dirname $0); pwd)
. ./var.conf


pushd /tmp

### Install
wget https://download-cf.jetbrains.com/upsource/upsource-2017.1.1781.zip
unzip -q upsource-2017.1.1781.zip
mv upsource-2017.1.1781 /opt/

cat <<EOF >> /etc/security/limits.conf
* - memlock unlimited
* - nofile 100000
* - nproc 32768
* - as unlimited
EOF


### Restore Settings Data.
pushd /opt/upsource-2017.1.1781

#./bin/upsource.sh configure --listen-port 9800 --base-url http://localhost/upsource/
#./bin/upsource.sh configure -J-Djava.awt.headless=true

unzip -q "${CURDIR}"/conf/upsource_data.zip -d /tmp/
\cp -rf /tmp/upsource_data/conf/* ./conf/
\cp -rf /tmp/upsource_data/data/* ./data/

mkdir /tmp/hub_data/
unzip -q "${CURDIR}"/conf/hub_data.zip -d /tmp/hub_data/
\cp -rf /tmp/hub_data/conf/* ./conf/
\cp -rf /tmp/hub_data/hub ./data/

popd


### Sevice
cp "${CURDIR}"/conf/upsource-2017.1.service /etc/systemd/system/

systemctl enable upsource-2017.1.service
systemctl start upsource-2017.1.service


### Apache proxy
cp "${CURDIR}"/conf/upsource_proxy.conf /etc/httpd/conf.d/
systemctl restart httpd.service
