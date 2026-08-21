#!/bin/bash

INSTANCE_TYPE="t3.micro"
SG_NAME="q8-ssh-anywhere"

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

SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "SSH from anywhere" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q8-Instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].[InstanceId,Tags[?Key==`Name`].Value|[0],PublicDnsName]' \
    --output table
