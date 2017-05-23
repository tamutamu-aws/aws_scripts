#!/bin/bash

CURDIR=$(cd $(dirname $0); pwd)

mkdir $CURDIR/tmp
chmod a+w $CURDIR/tmp

export no_proxy=localhost

curl -X POST -u admin:password http://localhost:8080/artifactory/api/export/system -d "@export-settings.json" -k -H "Content-Type: application/json"

cd /tmp/artifactory
mv *.zip settings.zip
mv settings.zip $CURDIR/

echo "Export $CURDIR/settings.zip"
