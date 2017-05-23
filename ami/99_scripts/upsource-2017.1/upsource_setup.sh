#!/bin/bash
set -euo pipefail

pushd /opt/upsource-2017.1.1781
systemctl stop upsource-2017.1
./bin/upsource.sh configure --listen-port 9800 --base-url http://$1/upsource/
systemctl start upsource-2017.1
popd
