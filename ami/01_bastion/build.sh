#!/bin/bash
set -euo pipefail

. ../../config/credentials.sh
. ../../config/stack_env.sh
. ../../scripts/utils/common.sh
. ../../scripts/utils/ssh.sh
. ../../scripts/aws/ec2.sh

. var.conf


### Create temporary ec2.
readonly tmp_key_name=ami_build_$(date "+%Y%m%d_%H%M%S")
readonly tmp_key_file_path=./tmp_private_key.pem

readonly instance_id=$(ec2:create_tmp_instance \
                                  "${SOURCE_AMI_ID}" \
                                  "${EC2_TYPE}" \
                                  "${tmp_key_name}" \
                                  "${tmp_key_file_path}")


readonly eip_id=$(ec2:get_eip_id "${BASTION_EIP_IP}")
aws ec2 associate-address --instance-id "${instance_id}" --allocation-id "${eip_id}"


### Provisioning.
set +e
ssh:remote_copy \
    ${BASTION_SSH_IP} \
    ${SOURCE_AMI_USER} \
    ${tmp_key_file_path} \
    ../99_scripts/clamav/ \
    /tmp/

ssh:remote_exec_shell_script \
    ${BASTION_SSH_IP} \
    ${SOURCE_AMI_USER} \
    ${tmp_key_file_path} \
    ./provision.sh \
     /tmp/ \
    "cd /tmp/ && sudo -E ./provision.sh ${GENERAL_USER} ${SOURCE_AMI_USER}"
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
