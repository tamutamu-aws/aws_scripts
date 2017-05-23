#!/bin/bash
set -euo pipefail


### Install awscli
if [[ -z $(which aws 2> /dev/null) ]]; then
  echo "Missing awscli Install awscli"
  yum -y install python-pip > /dev/null
  pip install awscli > /dev/null
fi


### Install jq.
if [[ -z $(which jq 2> /dev/null) ]]; then
  echo "Missing jq. Install jq."
  yum install -y epel-release > /dev/null
  yum --enablerepo=epel install -y jq > /dev/null
fi


### Create credentials.sh 
echo "Please Input AWS_ACCESS_KEY_ID ="
read aws_access_key_id

echo "Please Input AWS_SECRET_ACCESS_KEY ="
read aws_secret_access_key

echo "Please Input AWS_EC2_PRIV_KEY_PATH ="
read aws_ec2_priv_key_path


cat << EOF > ../config/credentials.sh
### Credentials
declare -xr AWS_ACCESS_KEY_ID=${aws_access_key_id}
declare -xr AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
declare -xr AWS_EC2_PRIV_KEY_PATH=${aws_ec2_priv_key_path}
EOF
