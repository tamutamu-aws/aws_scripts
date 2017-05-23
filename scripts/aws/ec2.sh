### ec2:check_exist_SG [security group name]
ec2:check_exist_SG() {
  local _ret="$(aws ec2 describe-security-groups --filters Name=group-name,Values="${1}" \
              | jq -r '.SecurityGroups[].GroupId')"

  if [[ -n "${_ret}" ]]; then
    common:r_echo "Error!!."
    common:r_echo "Security Group "${1}" already exists."
    echo 
    common:m_echo "Delete Security Group "${1}"."
    exit 1
  fi
}


### ec2:create_instance [ec2 name] [ami name] [key name] [security group id] [ec2 type] [subnet id]
ec2:create_instance() {
  local readonly _ec2_name="${1}"
  local readonly _ami_id="${2}"
  local readonly _key_name="${3}"
  local readonly _sg_name="${4}"
  local readonly _ec2_type="${5}"
  local readonly _volume_size="${6}"
  local readonly _subnet_id="${7}"

  local _ret="$(aws ec2 run-instances \
                 --image-id "${_ami_id}" \
                 --key-name "${_key_name}" \
                 --security-group-ids "${_sg_name}" \
                 --subnet-id "${_subnet_id}" \
                 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":'${_volume_size}',"DeleteOnTermination":false,"VolumeType":"gp2"}}]' \
                 --instance-type "${_ec2_type}")"
  
  local readonly _instance_id="$(echo "${_ret}" | jq -r ".Instances[].InstanceId")"
  aws ec2 create-tags --resources "${_instance_id}" --tags Key=Name,Value="${_ec2_name}" > /dev/null

  echo "${_instance_id}"
}


### ec2:create_tmp_instance [ami id] [key name] [ec2 type]
ec2:create_tmp_instance() {
  local readonly _ami_id="${1}"
  local readonly _ec2_type="${2}"
  local readonly _tmp_key_name="${3}"
  local readonly _tmp_key_file_path="${4}"


  ec2:create_tmp_keypair ${_tmp_key_name} ${_tmp_key_file_path}

  # Security Group for SSH
  local readonly _sg_id=$(aws ec2 create-security-group --group-name "AMI_BUILD_SHAccess_$(date "+%Y%m%d_%H%M%S")" \
                                                         --description "AMI_BUILD SSH access for AMI build." \
                          | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id "${_sg_id}" --protocol tcp --port 22 --cidr 0.0.0.0/0


  local _ret="$(aws ec2 run-instances \
                 --image-id "${_ami_id}" \
                 --key-name "${_tmp_key_name}" \
                 --security-group-ids "${_sg_id}" \
                 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":8,"DeleteOnTermination":true,"VolumeType": "gp2"}}]' \
                 --instance-type "${_ec2_type}")"
  
  local readonly _instance_id="$(echo "${_ret}" | jq -r ".Instances[].InstanceId")"


  aws ec2 wait instance-running --instance-id="${_instance_id}"
  aws ec2 create-tags --resources ${_instance_id} --tags Key=Name,Value=AMI_BUILD


  echo "${_instance_id}"
}


### ec2:create_tmp_keypair [key name] [private key path]
ec2:create_tmp_keypair() {
  local readonly _key_name="${1}"
  local readonly _key_file_path="${2}"

  aws ec2 create-key-pair \
    --key-name ${_key_name} \
    --query 'KeyMaterial' \
    --output text \
      > ${_key_file_path} \
      && chmod 400 ${_key_file_path}
}


### ec2:get_public_ip [instance id]
ec2:get_public_ip() {
  local readonly _instance_id="${1}"

  echo $(aws ec2 describe-instances --instance-id ${_instance_id} \
         | jq -r '.Reservations[].Instances[] | .PublicIpAddress')
}


### ec2:get_eip_id [eip ip]
ec2:get_eip_id() {
  local readonly _eip_ip="${1}"

  echo $(aws ec2 describe-addresses --filters "Name=public-ip,Values=${_eip_ip}" \
        | jq -r '.Addresses[].AllocationId')
}


### ec2:find_ami_id_for_name [ami Name tag value]
ec2:find_ami_id_for_name() {
  local _ret="$(aws ec2 describe-images \
     --owners self \
     --filters "Name=name,Values="${1}"")"
  
  echo "${_ret}" | jq -r '.Images[] | .ImageId'
}


### ec2:default_setup [ec2 ssh ip] \
###                   [ec2 ssh user] \
###                   [ec2 ssh key path] \ 
###                   [setup script path]
###                   [execute cmd for setup script]
ec2:default_setup() {
  local readonly _ssh_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _setupScriptPath="${4}"
  local readonly _exec_cmd="${5}"
  
  ssh:remote_copy \
      ${_ssh_ip} \
      ${_ssh_user} \
      ${_ec2_private_key_path} \
      ${_setupScriptPath} \
      /tmp/

  ssh:remote_exec_shell_script \
      ${_ssh_ip} \
      ${_ssh_user} \
      ${_ec2_private_key_path} \
      ${_setupScriptPath} \
       /tmp/ \
      "${_exec_cmd}"
}
