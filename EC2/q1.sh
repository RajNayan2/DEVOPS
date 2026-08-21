#!/bin/bash

INSTANCE_TYPE="t3.micro"

echo "Finding Ubuntu 22.04 AMI..."

AMI_ID=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
    --query 'Parameter.Value' \
    --output text)

if [ $? -ne 0 ]; then
    echo "ERROR: Ubuntu AMI not found"
    exit 1
fi

VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

echo "AMI: $AMI_ID"
echo "VPC: $VPC_ID"
echo "Subnet: $SUBNET_ID"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Assignment5-Q1}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "ERROR: Instance creation failed"
    exit 1
fi

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

echo
echo "Instance ID: $INSTANCE_ID"

aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].[InstanceId,InstanceType,State.Name,PrivateIpAddress,PublicIpAddress]' \
    --output table
