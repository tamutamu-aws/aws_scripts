#!/bin/bash
set -euo pipefail

. ../../config/credentials.sh
. ../../config/stack_env.sh
. ../../scripts/utils/common.sh
. ../../scripts/utils/ssh.sh
. ../../scripts/aws/ec2.sh

. var.conf

### Create temporary ec2.
set +e
readonly tmp_key_name=ami_build_$(date "+%Y%m%d_%H%M%S")
readonly tmp_key_file_path=./tmp_private_key.pem

readonly instance_id=$(ec2:create_tmp_instance \
                                  "${SOURCE_AMI_ID}" \
                                  "${EC2_TYPE}" \
                                  "${tmp_key_name}" \
                                  "${tmp_key_file_path}")

readonly public_ip=$(ec2:get_public_ip "${instance_id}")
set -e


### Provisioning.
set +e
remote_copy(){
  ssh:remote_copy_with_proxy \
    ${public_ip} \
    ${SOURCE_AMI_USER} \
    ${tmp_key_file_path} \
    $1 \
    /tmp/ ${BASTION_SSH_IP} ${GENERAL_USER} ${GENERAL_USER_KEY_PATH}
}

remote_copy '../99_scripts/common-dev/'
remote_copy '../99_scripts/aws/'
remote_copy '../99_scripts/clamav/'
remote_copy '../99_scripts/java/'

ssh:remote_exec_shell_script_with_proxy \
    ${public_ip} \
    ${SOURCE_AMI_USER} \
    ${tmp_key_file_path} \
    ./provision.sh \
     /tmp/ \
    "cd /tmp/ && sudo -E ./provision.sh ${GENERAL_USER} ${SOURCE_AMI_USER}" \
    ${BASTION_SSH_IP} \
    ${GENERAL_USER} \
    ${GENERAL_USER_KEY_PATH}
set -e


### Create AMI.
readonly ami_id=$(aws ec2 create-image --instance-id "${instance_id}" --name "${AMI_NAME}_$(date "+%Y%m%d_%H%M%S")" --reboot \
                  | jq -r '.ImageId')
aws ec2 create-tags --resources ${ami_id} --tags Key=Name,Value=${AMI_NAME}


# Celan up
##readonly _sg_id=$(aws ec2 describe-instances --instance-id "${instance_id}" \
##                       | jq -r '.Reservations[].Instances[].SecurityGroups[].GroupId')
##aws ec2 terminate-instances --instance-id "${instance_id}"
##aws ec2 wait instance-terminated --instance-id="${instance_id}"

##aws ec2 delete-security-group --group-id ${_sg_id} 
##aws ec2 delete-key-pair --key-name "${_tmp_key_name}"
##rm -f "${_tmp_key_file_path}"
