########################################################################
#  ___         _           _____                       __           
# |   \  __ _ | |_  __ _  |_   _|_ _  __ _  _ _   ___ / _| ___  _ _ 
# | |) |/ _` ||  _|/ _` |   | | | '_|/ _` || ' \ (_-<|  _|/ -_)| '_|
# |___/ \__,_| \__|\__,_|   |_| |_|  \__,_||_||_|/__/|_|  \___||_|  
#                                                                   
########################################################################

#!/bin/bash

source ./utils.sh

REGION=$(aws configure get region)

log_info "Auditing data transfer risks in $REGION"
echo "--------------------------------------------------"

# 1. Detect EC2 instances with public IPs
log_info "EC2 Instances with Public IPs:"
instances=$(aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,PublicIP:PublicIpAddress}' \
  --output json)

echo "$instances" | jq -r '.[][] | select(.PublicIP != null) | "Instance: \(.ID) has Public IP: \(.PublicIP)"'

# 2. Detect allocated Elastic IPs (EIPs)
log_info "Elastic IP Addresses (EIPs):"
eips=$(aws ec2 describe-addresses --query 'Addresses[*].{PublicIP:PublicIp,InstanceId:InstanceId}' --output json)

if [ -z "$eips" ] || [ "$eips" == "[]" ]; then
  log_success "No Elastic IPs allocated."
else
  echo "$eips" | jq -r '.[] | 
    if .InstanceId == null then
      "Unused Elastic IP: \(.PublicIP)"
    else
      "Elastic IP \(.PublicIP) attached to instance: \(.InstanceId)"
    end'
fi

# 3. Detect subnets spread across Availability Zones (AZs)
log_info "Subnet-AZ Mapping (check same-AZ design):"
aws ec2 describe-subnets \
  --query 'Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output json | jq -r '.[] | "  Subnet: \(.Name // .ID), AZ: \(.AZ)"'

# 4. Detect S3 and DynamoDB VPC Endpoints
log_info "VPC Endpoints (S3 & DynamoDB):"
s3_vpce=$(aws ec2 describe-vpc-endpoints \
  --query "VpcEndpoints[?contains(ServiceName, 's3')].ServiceName" \
  --output text)

ddb_vpce=$(aws ec2 describe-vpc-endpoints \
  --query "VpcEndpoints[?contains(ServiceName, 'dynamodb')].ServiceName" \
  --output text)

if [ -z "$s3_vpce" ]; then
  log_warn "No VPC endpoint for S3 detected"
else
  log_success "S3 VPC endpoint present: $s3_vpce"
fi

if [ -z "$ddb_vpce" ]; then
  log_warn "No VPC endpoint for DynamoDB detected"
else
  log_success "DynamoDB VPC endpoint present: $ddb_vpce"
fi

log_success "Data transfer risk audit completed."