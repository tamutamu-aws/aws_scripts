#!/bin/bash
 
# PATH
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
# clamd update
yum -y update clamd > /dev/null 2>&1
 
# virus scan
CLAMSCANTMP=`mktemp`
 
clamdscan --recursive --remove /  > $CLAMSCANTMP 2>&1

###MAIL_ADDR=
###[ ! -z "$(grep FOUND$ $CLAMSCANTMP)" ] && \
###grep FOUND$ $CLAMSCANTMP | mail -s "$(hostname) Virus Found" $MAIL_ADDR
### 
###[ -z "$(grep FOUND$ $CLAMSCANTMP)" ] && \
###echo "$(hostname) Virus Not Found" | mail -s "Virus Not Found" $MAIL_ADDR
 
rm -f $CLAMSCANTMP
