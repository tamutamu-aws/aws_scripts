### vpc:get_vpc_id [vpc cidr]
vpc:get_vpc_id() {
  local readonly _vpc_cidr="${1}"

  local readonly _vpc_id="$(aws ec2 describe-vpcs \
		--filter Name=cidr,Values="${_vpc_cidr}" \
		--query Vpcs[].VpcId \
		--output text)"

  echo "${_vpc_id}"
}


### vpc:get_subnet_id [subnet cidr]
vpc:get_subnet_id() {
  local readonly _subnet_cidr="${1}"

  local readonly _subnet_id="$(aws ec2 describe-subnets \
		--output text \
		--filter  "Name=cidrBlock,Values="${_subnet_cidr}""  \
		--query Subnets[].SubnetId)"

  echo "${_subnet_id}"
}


### vpc:create_vpc [vpc cidr] [vpc tag name]
vpc:create_vpc() {
  local readonly _vpc_cidr="${1}"
  local readonly _name="${2}"

  local readonly _vpc_id="$(aws ec2 create-vpc --cidr-block "${_vpc_cidr}" | jq -r .Vpc.VpcId)"
  aws ec2 wait vpc-available --vpc-ids "${_vpc_id}" > /dev/null
  aws ec2 create-tags --resources "${_vpc_id}" --tags Key=Name,Value="${_name}" > /dev/null

  echo "${_vpc_id}"
}


### vpc:create_igw [vpc id] [igw tag name]
vpc:create_igw() {
  local readonly _vpc_id="${1}"
  local readonly _name="${2}"

  local readonly _igw_id=$(aws ec2 create-internet-gateway | jq -r .InternetGateway.InternetGatewayId)
  aws ec2 attach-internet-gateway --internet-gateway-id "${_igw_id}" --vpc-id "${_vpc_id}" > /dev/null
  aws ec2 create-tags --resources "${_igw_id}" --tags Key=Name,Value="${_name}" > /dev/null

  echo "${_igw_id}"
}


### vpc:create_subnet [vpc id] [subnet cidr] [subnet tag name]
vpc:create_subnet() {
  local readonly _vpc_id="${1}"
  local readonly _subnet_cidr="${2}"
  local readonly _name="${2}"

  local readonly _subnet_id=$(aws ec2 create-subnet --vpc-id "${_vpc_id}" --cidr-block "${_subnet_cidr}" | jq -r .Subnet.SubnetId)
  aws ec2 wait subnet-available --subnet-ids "${_subnet_id}" > /dev/null
  aws ec2 create-tags --resources "${_subnet_id}" --tags Key=Name,Value="${_name}" > /dev/null
  
  echo "${_subnet_id}"
}


### vpc:create_rtb [vpc id]
vpc:create_rtb() {
  local readonly _vpc_id="${1}"

  local readonly _rtb_id=$(aws ec2 create-route-table --vpc-id "${_vpc_id}" | jq -r .RouteTable.RouteTableId)

  echo "${_rtb_id}"
}


### vpc:associate_rtb [route table id] [subnet id] 
vpc:associate_rtb() {
  local readonly _rtb_id="${1}"
  local readonly _subnet_id="${2}"

  aws ec2 associate-route-table --route-table-id "${_rtb_id}" --subnet-id "${_subnet_id}" > /dev/null
}

### vpc:create_route_for_igw [rtb id] [igw id] 
vpc:create_route_for_igw() {
  local readonly _rtb_id="${1}"
  local readonly _igw_id="${2}"

  aws ec2 create-route --route-table-id "${_rtb_id}" --destination-cidr-block 0.0.0.0/0 --gateway-id "${_igw_id}" > /dev/null
}
