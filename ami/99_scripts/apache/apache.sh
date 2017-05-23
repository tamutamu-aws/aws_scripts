#!/bin/bash
set -euo pipefail

echo "Install Apache." 

CURDIR=$(cd $(dirname $0); pwd)


yum -y install httpd httpd-devel libcurl-devel apr-util-devel apr-devel mod_ssl

systemctl enable httpd.service
systemctl start httpd.service
