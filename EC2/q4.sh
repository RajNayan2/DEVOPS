#!/bin/bash

INSTANCE_TYPE="t3.micro"
KEY_NAME="q4-key"
KEY_FILE="$HOME/$KEY_NAME.pem"
SG_NAME="q4-sg"

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

aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --query 'KeyMaterial' \
    --output text > "$KEY_FILE"

chmod 400 "$KEY_FILE"

SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "SSH and HTTP" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

MY_IP=$(curl -s https://checkip.amazonaws.com)

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "$MY_IP/32"

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q4-Nginx}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Public IP: $PUBLIC_IP"

ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    ubuntu@"$PUBLIC_IP" \
    'sudo apt update && sudo apt install nginx -y && sudo systemctl enable nginx && sudo systemctl start nginx'

echo
echo "Nginx installed."
echo "Open: http://$PUBLIC_IP"
