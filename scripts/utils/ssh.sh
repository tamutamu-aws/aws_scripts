ssh:remote_copy(){

  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _local_dir="${4}"
  local readonly _remote_dir="${5}"

  ssh:wait_connect "${_connect_ip}" "${_ssh_user}" "${_ec2_private_key_path}"
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r -i "${_ec2_private_key_path}" "${_local_dir}" "${_ssh_user}"@"${_connect_ip}":"${_remote_dir}"

}


ssh:remote_copy_with_proxy(){

  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _local_dir="${4}"
  local readonly _remote_dir="${5}"
  local readonly _bastion_ip="${6}"
  local readonly _bastion_ssh_user="${7}"
  local readonly _bastion_ssh_user_key_path="${8}"

  ssh:wait_connect_with_proxy "${_connect_ip}" "${_ssh_user}" "${_ec2_private_key_path}" "${_bastion_ip}" "${_bastion_ssh_user}"  "${_bastion_ssh_user_key_path}" 

  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o "ProxyCommand ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${_bastion_ssh_user_key_path} ${_bastion_ssh_user}@${_bastion_ip} -W %h:%p" \
      -r -i "${_ec2_private_key_path}" "${_local_dir}" "${_ssh_user}"@"${_connect_ip}":"${_remote_dir}"
}


ssh:remote_exec_shell_script(){
  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _local_script_path="${4}"
  local readonly _remote_path="${5}"
  local readonly _execute_cmd="${6}"

  local readonly _script_name=$(basename "${_local_script_path}")

  ssh:wait_connect "${_connect_ip}" "${_ssh_user}" "${_ec2_private_key_path}"
  
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "${_ec2_private_key_path}" "${_local_script_path}" "${_ssh_user}"@"${_connect_ip}":"${_remote_path}"
  ssh -t -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i "${_ec2_private_key_path}" "${_ssh_user}"@"${_connect_ip}" \
  "sudo chmod a+x ${_remote_path}/${_script_name} && ${_execute_cmd}"

}

ssh:remote_exec_shell_script_with_proxy(){
  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _local_script_path="${4}"
  local readonly _remote_path="${5}"
  local readonly _execute_cmd="${6}"
  local readonly _bastion_ip="${7}"
  local readonly _bastion_ssh_user="${8}"
  local readonly _bastion_ssh_user_key_path="${9}"

  local readonly _script_name=$(basename "${_local_script_path}")

  ssh:remote_copy_with_proxy ${_connect_ip} ${_ssh_user} ${_ec2_private_key_path} \
                             ${_local_script_path} ${_remote_path} ${_bastion_ip} \
			     ${_bastion_ssh_user} ${_bastion_ssh_user_key_path}
  
  ssh -t -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
      -o "ProxyCommand ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${_bastion_ssh_user_key_path} ${_bastion_ssh_user}@${_bastion_ip} -W %h:%p" \
      -i "${_ec2_private_key_path}" "${_ssh_user}"@"${_connect_ip}" \
      "sudo chmod a+x ${_remote_path}/${_script_name} && ${_execute_cmd}"
}


ssh:wait_connect(){

  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"

  local _retry=0
  local readonly _ssh_max_retry=15
  local _ret=""

  while true
  do
    ssh -t -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
        -o "ConnectTimeout 20" \
        -i "${_ec2_private_key_path}" "${_ssh_user}"@"${_connect_ip}" "sudo ls" > /dev/null 2>&1

   echo "$?"

    _ret="$?"
    [ "${_ret}" = "0" ] && break || echo "ssh: timeout, reconnect.. "
  
    _retry=`expr "${_retry}" + 1`
    [ "${_retry}" -eq "${_ssh_max_retry}" ] && (util:r_echo "ssh error: retry max."; exit 1)
  
    sleep 15
  done

  sleep 15
}


ssh:wait_connect_with_proxy(){

  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ec2_private_key_path="${3}"
  local readonly _bastion_ip="${4}"
  local readonly _bastion_ssh_user="${5}"
  local readonly _bastion_ssh_user_key_path="${6}"

  local _retry=0
  local readonly _ssh_max_retry=15
  local _ret=""

  while true
  do
    ssh -t -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
        -o "ConnectTimeout 5" \
	-o "ProxyCommand ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${_bastion_ssh_user_key_path} ${_bastion_ssh_user}@${_bastion_ip} -W %h:%p" \
        -i "${_ec2_private_key_path}" "${_ssh_user}"@"${_connect_ip}" "sudo ls" > /dev/null 2>&1

   echo "$?"

    _ret="$?"
    [ "${_ret}" = "0" ] && break || echo "ssh: timeout, reconnect.. "
  
    _retry=`expr "${_retry}" + 1`
    [ "${_retry}" -eq "${_ssh_max_retry}" ] && (util:r_echo "ssh error: retry max."; exit 1)
  
    sleep 15
  done

  sleep 15
}
