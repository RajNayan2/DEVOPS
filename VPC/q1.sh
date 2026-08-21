#!/bin/bash

set -e

REGION=$(aws configure get region)

VPC_CIDR="10.0.0.0/16"
PUBLIC_CIDR="10.0.1.0/24"
PRIVATE_CIDR="10.0.2.0/24"

echo "======================================"
echo "Assignment 7 - Question 1"
echo "======================================"

# --------------------------------------
# Create VPC
# --------------------------------------

echo
echo "Creating VPC..."

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --tag-specifications \
    'ResourceType=vpc,Tags=[{Key=Name,Value=Assignment7-VPC}]' \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC ID: $VPC_ID"

# --------------------------------------
# Enable DNS
# --------------------------------------

aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-support "{\"Value\":true}"

aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames "{\"Value\":true}"

# --------------------------------------
# Get Availability Zone
# --------------------------------------

AZ=$(aws ec2 describe-availability-zones \
    --filters Name=state,Values=available \
    --query 'AvailabilityZones[0].ZoneName' \
    --output text)

echo "Availability Zone: $AZ"

# --------------------------------------
# Create Public Subnet
# --------------------------------------

echo
echo "Creating public subnet..."

PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PUBLIC_CIDR" \
    --availability-zone "$AZ" \
    --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=Assignment7-Public}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet: $PUBLIC_SUBNET_ID"

# --------------------------------------
# Create Private Subnet
# --------------------------------------

echo
echo "Creating private subnet..."

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PRIVATE_CIDR" \
    --availability-zone "$AZ" \
    --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=Assignment7-Private}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet: $PRIVATE_SUBNET_ID"

# --------------------------------------
# Internet Gateway
# --------------------------------------

echo
echo "Creating Internet Gateway..."

IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications \
    'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Assignment7-IGW}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "IGW: $IGW_ID"

echo "Attaching IGW..."

aws ec2 attach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID"

# --------------------------------------
# Public Route Table
# --------------------------------------

echo
echo "Creating public route table..."

PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications \
    'ResourceType=route-table,Tags=[{Key=Name,Value=Assignment7-Public-RT}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Public Route Table: $PUBLIC_RT_ID"

echo "Adding Internet route..."

aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID"

echo "Associating public subnet..."

aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_RT_ID" \
    --subnet-id "$PUBLIC_SUBNET_ID"

# --------------------------------------
# Allocate Elastic IP
# --------------------------------------

echo
echo "Allocating Elastic IP..."

ALLOCATION_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --query 'AllocationId' \
    --output text)

echo "Allocation ID: $ALLOCATION_ID"

# --------------------------------------
# NAT Gateway
# --------------------------------------

echo
echo "Creating NAT Gateway..."

NAT_ID=$(aws ec2 create-nat-gateway \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --allocation-id "$ALLOCATION_ID" \
    --tag-specifications \
    'ResourceType=natgateway,Tags=[{Key=Name,Value=Assignment7-NAT}]' \
    --query 'NatGateway.NatGatewayId' \
    --output text)

echo "NAT Gateway: $NAT_ID"

echo
echo "Waiting for NAT Gateway..."

aws ec2 wait nat-gateway-available \
    --nat-gateway-ids "$NAT_ID"

# --------------------------------------
# Private Route Table
# --------------------------------------

echo
echo "Creating private route table..."

PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications \
    'ResourceType=route-table,Tags=[{Key=Name,Value=Assignment7-Private-RT}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Private Route Table: $PRIVATE_RT_ID"

echo "Adding NAT route..."

aws ec2 create-route \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id "$NAT_ID"

echo "Associating private subnet..."

aws ec2 associate-route-table \
    --route-table-id "$PRIVATE_RT_ID" \
    --subnet-id "$PRIVATE_SUBNET_ID"

# --------------------------------------
# Summary
# --------------------------------------

echo
echo "======================================"
echo "VPC SETUP COMPLETED"
echo "======================================"

echo "VPC ID           : $VPC_ID"
echo "Public Subnet    : $PUBLIC_SUBNET_ID"
echo "Private Subnet   : $PRIVATE_SUBNET_ID"
echo "Internet Gateway : $IGW_ID"
echo "NAT Gateway      : $NAT_ID"
echo "Public RT        : $PUBLIC_RT_ID"
echo "Private RT       : $PRIVATE_RT_ID"
echo "======================================"
