#!/bin/bash

INSTANCE_TYPE="t3.micro"

echo "Finding latest Ubuntu LTS..."

AMI_ID=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
    --query 'Parameter.Value' \
    --output text)

if [ $? -ne 0 ]; then
    echo "ERROR: Ubuntu LTS AMI not found."
    exit 1
fi

echo "Latest Ubuntu LTS AMI: $AMI_ID"

VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q10-Latest-LTS}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"
