#!/bin/bash
set -euo pipefail

. ../../config/credentials.sh
. ../../config/stack_env.sh
. ../../scripts/aws/vpc.sh


### Create VPC
declare -r vpc_id="$(vpc:create_vpc "${VPC_CIDR}" "${STACK_NAME}")"


### Create Internet Gateway
declare -r igw_id="$(vpc:create_igw "${vpc_id}" "${STACK_NAME}")"


### Create Subnet, public and private 
declare -r pub_subnet_id="$(vpc:create_subnet "${vpc_id}" "${PUBLIC_SUBNET_CIDR}" "${STACK_NAME}"-public)"
declare -r priv_subnet_id="$(vpc:create_subnet "${vpc_id}" "${PRIVATE_SUBNET_CIDR}" "${STACK_NAME}"-private)"


### Create and Associate Route table, public and private
declare -r pub_rtb_id="$(vpc:create_rtb "${vpc_id}")"
declare -r priv_rtb_id="$(vpc:create_rtb "${vpc_id}")"
vpc:associate_rtb "${pub_rtb_id}" "${pub_subnet_id}"
vpc:associate_rtb "${priv_rtb_id}" "${priv_subnet_id}"


### Add Internet Gateway to Route table 
vpc:create_route_for_igw "${pub_rtb_id}" "${igw_id}"
vpc:create_route_for_igw "${priv_rtb_id}" "${igw_id}"
