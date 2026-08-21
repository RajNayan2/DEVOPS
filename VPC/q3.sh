#!/bin/bash

source vars.env

AZ=$(aws ec2 describe-availability-zones \
    --filters Name=state,Values=available \
    --query 'AvailabilityZones[0].ZoneName' \
    --output text)

echo "Using Availability Zone: $AZ"

echo "Creating public subnet..."

PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.1.0/24 \
    --availability-zone "$AZ" \
    --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=Assignment7-Public}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet: $PUBLIC_SUBNET_ID"

echo "Creating private subnet..."

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.2.0/24 \
    --availability-zone "$AZ" \
    --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=Assignment7-Private}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet: $PRIVATE_SUBNET_ID"

cat >> vars.env <<EOF
PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID
AZ=$AZ
EOF

echo
echo "Updated vars.env:"
cat vars.env
