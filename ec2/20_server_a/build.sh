#!/bin/bash -x
set -euo pipefail

. ../../config/credentials.sh
. ../../config/stack_env.sh
. ../../scripts/utils/common.sh
. ../../scripts/utils/ssh.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh
. ./var.conf


### Get VPC Info.
declare -r vpc_id="$(vpc:get_vpc_id "${VPC_CIDR}")"
declare -r subnet_id="$(vpc:get_subnet_id "${PUBLIC_SUBNET_CIDR}")"


## Create Security Group.
ec2:check_exist_SG "${EC2_NAME}"
declare -r sg_id="$(aws ec2 create-security-group --group-name "${EC2_NAME}" --vpc-id "${vpc_id}" --description "${EC2_NAME}" | jq -r '.GroupId')"

# ssh
aws ec2 authorize-security-group-ingress --group-id "${sg_id}" --protocol 'tcp' --port 22 --cidr ${BASTION_EIP_IP}/32
aws ec2 authorize-security-group-ingress --group-id "${sg_id}" --protocol 'tcp' --port 80 --cidr 0.0.0.0/0


### create EC2 instance
set +e
declare -r instance_id=$(ec2:create_instance "${EC2_NAME}" "${AMI_ID}" "${KEY_NAME}" "${sg_id}" "${INSTANCE_TYPE}" "${VOL_SIZE}" "${subnet_id}")
aws ec2 wait instance-running --instance-id="${instance_id}"

# Associate EIP
readonly eip_id=$(ec2:get_eip_id "${SERVER_A_IP}")
aws ec2 associate-address --instance-id "${instance_id}" --allocation-id "${eip_id}" > /dev/null
set -e


## EC2 default setup
set +e
ssh:remote_exec_shell_script_with_proxy \
      ${SERVER_A_IP} \
      ${GENERAL_USER} \
      ${AWS_EC2_PRIV_KEY_PATH} \
      '../../scripts/aws/ec2_init/ec2_init.sh' \
      /tmp/ \
      "sudo /tmp/ec2_init.sh ${AWS_DEFAULT_REGION} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} ${AWS_S3_BUCKET}" \
      ${BASTION_SSH_IP} \
      ${GENERAL_USER} \
      ${GENERAL_USER_KEY_PATH}

ssh:remote_exec_shell_script_with_proxy \
      ${SERVER_A_IP} \
      ${GENERAL_USER} \
      ${AWS_EC2_PRIV_KEY_PATH} \
      '../../ami/99_scripts/upsource-2017.1/upsource_setup.sh' \
      /tmp/ \
      "sudo /tmp/upsource_setup.sh ${SERVER_A_IP}" \
      ${BASTION_SSH_IP} \
      ${GENERAL_USER} \
      ${GENERAL_USER_KEY_PATH}
set -e


echo "EC2 "${EC2_NAME}" instance start."
