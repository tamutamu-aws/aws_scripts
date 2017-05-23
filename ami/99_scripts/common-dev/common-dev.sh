#!/bin/bash
set -euo pipefail

echo "Install Common DevTools."
CURDIR=$(cd $(dirname $0); pwd)


### Settings
yum -y install wget vim
wget http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/7/x86_64/e/epel-release-7-9.noarch.rpm -P /tmp/
yum -y localinstall /tmp/epel-release-7-9.noarch.rpm
yum -y update
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
rm -f /root/.ssh/authorized_keys


### Common Dev tools
yum -y groupinstall "Development Tools"
yum -y install openssl-devel curl-devel expat-devel perl-ExtUtils-MakeMaker


### Git
yum -y remove git
wget https://www.kernel.org/pub/software/scm/git/git-2.11.0.tar.gz -P /tmp/
pushd /tmp/
tar zxf git-2.11.0.tar.gz
cd git-2.11.0
make prefix=/usr/local all
make prefix=/usr/local install
popd

