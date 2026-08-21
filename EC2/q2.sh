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

AZ=$(aws ec2 describe-subnets \
    --subnet-ids "$SUBNET_ID" \
    --query 'Subnets[0].AvailabilityZone' \
    --output text)

echo "Creating first instance..."

OLD_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q2-Old}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "Failed to create old instance"
    exit 1
fi

aws ec2 wait instance-running --instance-ids "$OLD_INSTANCE"

echo "Old Instance: $OLD_INSTANCE"

echo "Creating EBS volume..."

VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone "$AZ" \
    --size 8 \
    --volume-type gp3 \
    --query 'VolumeId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "Failed to create volume"
    exit 1
fi

aws ec2 wait volume-available --volume-ids "$VOLUME_ID"

echo "Volume: $VOLUME_ID"

echo "Attaching volume to old instance..."

aws ec2 attach-volume \
    --volume-id "$VOLUME_ID" \
    --instance-id "$OLD_INSTANCE" \
    --device /dev/sdf

sleep 5

echo "Terminating old instance..."

aws ec2 terminate-instances \
    --instance-ids "$OLD_INSTANCE"

aws ec2 wait instance-terminated \
    --instance-ids "$OLD_INSTANCE"

echo "Old instance terminated."

echo "Creating new instance..."

NEW_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q2-New}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "Failed to create new instance"
    exit 1
fi

aws ec2 wait instance-running --instance-ids "$NEW_INSTANCE"

echo "New Instance: $NEW_INSTANCE"

echo "Attaching EBS volume..."

aws ec2 attach-volume \
    --volume-id "$VOLUME_ID" \
    --instance-id "$NEW_INSTANCE" \
    --device /dev/sdf

echo
echo "================================="
echo "NEW INSTANCE ID: $NEW_INSTANCE"
echo "EBS VOLUME ID:   $VOLUME_ID"
echo "================================="
