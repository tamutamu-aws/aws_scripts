#!/bin/bash
set -euo pipefail

echo 'Install maven3'
CURDIR=$(cd $(dirname $0); pwd)


pushd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip 
unzip -q apache-maven-3.3.3-bin.zip
mv apache-maven-3.3.3 /opt/maven
ln -s /opt/maven/bin/mvn /usr/bin/mvn

cat << 'EOT' > /etc/profile.d/maven3.sh 
export MAVEN_HOME=/opt/maven
EOT
 
. /etc/profile.d/maven3.sh 
popd


