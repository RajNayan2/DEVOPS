#!/bin/bash

source vars.env

INSTANCE_TYPE="t3.micro"

echo "Finding Ubuntu 22.04 AMI..."

AMI_ID=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
    --query 'Parameter.Value' \
    --output text)

echo "AMI: $AMI_ID"

echo "Launching public EC2..."

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --associate-public-ip-address \
    --user-data file://q6-user-data.sh \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7-Public-Web}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "ERROR: EC2 creation failed."
    exit 1
fi

echo "Instance ID: $INSTANCE_ID"

aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo
echo "Instance is running."
echo "Public IP: $PUBLIC_IP"

cat >> vars.env <<EOF
PUBLIC_INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
EOF

echo
echo "Testing HTTP..."

sleep 10

curl -I "http://$PUBLIC_IP"

