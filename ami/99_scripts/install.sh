#!/bin/bash -eux

### execute provisoning scripts
BASEDIR=/var/packer_build

### base
(cd $BASEDIR/base && ./base.sh)


### common develop
(cd $BASEDIR/common-dev && ./common-dev.sh)


### aws utility
#(cd $BASEDIR/aws && ./aws.sh)


### Java(6,7,8), Maven, Gradle
(cd $BASEDIR/java && ./jdk.sh)
(cd $BASEDIR/java && ./maven-3.sh)
(cd $BASEDIR/java && ./gradle-2.sh)


### Apache 
(cd $BASEDIR/apache && ./apache.sh)


### database
#(cd $BASEDIR/oracle-11g && oracle-11g.sh)
#(cd $BASEDIR/oracle-12c && oracle-12c.sh)
#(cd $BASEDIR/db2-11 && db2-11.sh)
#(cd $BASEDIR/mysql-5.7 && ./mysql-5.7.sh)
#(cd $BASEDIR/postgresql-9.6 && ./postgresql-9.6.sh)
#(cd $BASEDIR/openldap && ./openldap.sh)


### Tomcat develop
#(cd $BASEDIR/tomcat-8 && ./tomcat-8.sh)
#(cd $BASEDIR/jenkins-2 && ./jenkins-2.sh)


### Weblogic12c
#(cd $BASEDIR/weblogic-12c && ./weblogic-12c.sh)


### ruby develop


### redmine

