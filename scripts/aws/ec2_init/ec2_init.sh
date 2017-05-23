#!/bin/bash
set -euo pipefail

declare -r aws_region=$1
declare -r aws_access_key_id=$2
declare -r aws_secret_access_key=$3
declare -r aws_s3_bucket=$4


### Configure aws config.
mkdir -p /root/.aws

cat << EOL > /root/.aws/config
[default]
output = text
region = $aws_region
EOL

cat << EOL > /root/.aws/credentials
[default]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
EOL


### s3 mount, when System startup.
mkdir /mnt/s3

declare -r per_boot_dir=/var/lib/cloud/scripts/per-boot

cat << EOL > $per_boot_dir/s3mount.sh
#!/bin/bash
sudo goofys -o allow_other --dir-mode 07777 --file-mode 0777 $aws_s3_bucket /mnt/s3/
EOL

chmod a+x $per_boot_dir/s3mount.sh
$per_boot_dir/s3mount.sh

ln -s /mnt/s3 /var/s3-"${aws_s3_bucket}"


### Setup hostname.
cat << EOL > /etc/cloud/cloud.cfg.d/update_hostname.cfg
preserve_hostname: true
EOL

declare -r instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
declare -r server_name=$(aws ec2 describe-instances \
                  --instance-id ${instance_id} \
                  --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' \
                  --output text)

hostnamectl set-hostname $server_name
