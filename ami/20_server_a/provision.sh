#!/bin/bash
set -euo pipefail


find ./ -name '*.sh' -type f -print | xargs chmod +x


(cd ./apache && ./apache.sh)
(cd ./tomcat-8 && ./tomcat-8.sh)
(cd ./artifactory-5.1 && ./artifactory-5.1.sh)
(cd ./mysql-5.7 && ./mysql-5.7.sh)
(cd ./sonar-6.2 && ./sonar-6.2.sh)
(cd ./upsource-2017.1 && ./upsource-2017.1.sh)


rm -rf /tmp/*
