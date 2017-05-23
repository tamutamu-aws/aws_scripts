#!/bin/bash
set -euo pipefail

declare -r aws_region=$1
declare -r aws_access_key_id=$2
declare -r aws_secret_access_key=$3

### Update ssh-key of general user.
##if getent passwd $general_user > /dev/null; then
##  mkdir -p $home_dir/.ssh
##  wget -q -O - http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > $home_dir/.ssh/authorized_keys
##
##  touch $home_dir/.ssh/OVERWRITE_authorized_keys_AT_BOOT
##
##  chown -R $general_user:$general_user $home_dir/.ssh
##  chmod 600 $home_dir/.ssh/authorized_keys
##fi

### Setup hostname.
cat << EOL > /etc/cloud/cloud.cfg.d/update_hostname.cfg
preserve_hostname: true
EOL


export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_region}"

declare -r instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
declare -r server_name=$(aws ec2 describe-instances \
                  --instance-id ${instance_id} \
                  --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' \
                  --output text)

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_DEFAULT_REGION

hostnamectl set-hostname $server_name


### Cleanup
rm -rf /tmp/*
