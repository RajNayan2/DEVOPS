#!/bin/bash

INSTANCE_TYPE="t3.micro"

AMI_ID=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
    --query 'Parameter.Value' \
    --output text)

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
    'ResourceType=instance,Tags=[{Key=Name,Value=Q7-EIP}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

EIP=$(aws ec2 describe-addresses \
    --filters "Name=instance-id,Values=$INSTANCE_ID" \
    --query 'Addresses[0].PublicIp' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

if [ "$EIP" = "None" ] || [ -z "$EIP" ]; then
    echo "Elastic IP: NOT ASSIGNED"
else
    echo "Elastic IP: $EIP"
fi
