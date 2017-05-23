#!/bin/bash
set -euo pipefail

general_user="${1}"
source_ami_user="${2}"

### SELinux
setenforce 0
sed -i.bak -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


### Settings
yum -y install wget vim
wget http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/7/x86_64/e/epel-release-7-9.noarch.rpm -P /tmp/
yum -y localinstall /tmp/epel-release-7-9.noarch.rpm
yum -y clean all
yum -y update
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
rm -f /root/.ssh/authorized_keys


### Common Dev tools
yum -y groupinstall "Development Tools"
yum -y install openssl-devel curl-devel expat-devel perl-ExtUtils-MakeMaker

### awscli
yum -y install python-pip
pip install awscli


### Clamav
find ./ -name '*.sh' -type f -print | xargs chmod +x
(cd ./clamav && ./clamav.sh)


### Configure secure sshd_config
readonly sshd_cfg=/etc/ssh/sshd_config

sed -i.bak -e 's/^#Protocol 2/Protocol 2/' \
    -i.bak -e 's/^#RhostsRSAAuthentication no/RhostsRSAAuthentication no/' \
    -i.bak -e 's/^#HostbasedAuthentication no/HostbasedAuthentication no/' \
    -i.bak -e 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' \
    -i.bak -e 's/^#RSAAuthentication yes/RSAAuthentication no/' \
    -i.bak -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -i.bak -e 's/^#PermitRootLogin yes/PermitRootLogin no/' \
    -i.bak -e 's/^#AddressFamily any/AddressFamily inet/' \
   $sshd_cfg

### Disable PortForwarding Settings.
##    -i.bak -e 's/~#AllowTcpForwarding yes/AllowTcpForwarding no/' \
##    -i.bak -e 's/^X11Forwarding yes/X11Forwarding no/' \

systemctl restart sshd.service


### Disable and stop unnecessary service
systemctl disable postfix.service
systemctl stop postfix.service


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



### Setting firewalld
##yum -y install firewalld
##systemctl start firewalld
##systemctl enable firewalld
##
##firewall-cmd --zone=public --add-interface=eth0
##firewall-cmd --remove-service=dhcpv6-client --permanent
##firewall-cmd --permanent --zone=public \
##  --add-rich-rule='rule family="ipv4" source address="0.0.0.0/32" destination address="0.0.0.0/32" port protocol="tcp" port="22" accept'
