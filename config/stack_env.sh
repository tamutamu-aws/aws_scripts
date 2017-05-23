### General
declare -xr AWS_DEFAULT_REGION=ap-southeast-1
declare -xr AWS_S3_BUCKET=nablarch-bucket
declare -xr GENERAL_USER=nablarch
declare -xr GENERAL_USER_KEY_PATH=/root/.ssh/nablarch-key.pem
declare -xr STACK_NAME=nablarch
declare -xr BASTION_SSH_IP=
declare -xr BASTION_FROM_ONLY=/


### EIP
declare -xr BASTION_EIP_IP=
declare -xr SERVER_A_IP=


### AMI BUILD
declare -r SOURCE_AMI_ID=ami-f068a193
declare -r DEV_BASE_AMI_ID=ami-7b69da18
declare -r SOURCE_AMI_USER=centos


### VPC
declare -xr VPC_CIDR=10.0.0.0/16
declare -xr PUBLIC_SUBNET_CIDR=10.0.0.0/24
declare -xr PRIVATE_SUBNET_CIDR=10.0.100.0/24
