#!/bin/bash

INSTANCE_TYPE="t3.micro"

KEY_NAME="q3-key"
KEY_FILE="$HOME/q3-key.pem"

SG_NAME="q3-sg"

echo "======================================"
echo "Assignment 5 - Question 3"
echo "======================================"

# --------------------------------------
# 1. Find Ubuntu 22.04 AMI
# --------------------------------------

echo
echo "Finding Ubuntu 22.04 AMI..."

AMI_ID=$(aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
    --query 'Parameter.Value' \
    --output text)

if [ $? -ne 0 ] || [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
    echo "ERROR: Ubuntu 22.04 AMI not found."
    exit 1
fi

echo "AMI ID: $AMI_ID"

# --------------------------------------
# 2. Find default VPC
# --------------------------------------

echo
echo "Finding default VPC..."

VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
    echo "ERROR: Default VPC not found."
    exit 1
fi

echo "VPC ID: $VPC_ID"

# --------------------------------------
# 3. Find subnet
# --------------------------------------

echo
echo "Finding subnet..."

SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo "ERROR: Subnet not found."
    exit 1
fi

echo "Subnet ID: $SUBNET_ID"

# --------------------------------------
# 4. Check existing key pair
# --------------------------------------

echo
echo "Checking key pair..."

if [ ! -f "$KEY_FILE" ]; then

    echo "Private key file does not exist."

    aws ec2 describe-key-pairs \
        --key-names "$KEY_NAME" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "ERROR: Key pair exists in AWS but private key file is missing."
        echo "AWS cannot download the private key again."
        exit 1
    fi

    echo "Creating new key pair..."

    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create key pair."
        exit 1
    fi

else

    echo "Private key already exists."
    echo "Using: $KEY_FILE"

fi

chmod 400 "$KEY_FILE"

# --------------------------------------
# 5. Find existing security group
# --------------------------------------

echo
echo "Checking security group..."

SG_ID=$(aws ec2 describe-security-groups \
    --filters \
    "Name=group-name,Values=$SG_NAME" \
    "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then

    echo "Security group does not exist."
    echo "Creating security group..."

    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SG_NAME" \
        --description "Q3 SSH Security Group" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' \
        --output text)

    if [ $? -ne 0 ] || [ -z "$SG_ID" ]; then
        echo "ERROR: Security group creation failed."
        exit 1
    fi

else

    echo "Security group already exists."
    echo "Security Group ID: $SG_ID"

fi

# --------------------------------------
# 6. Configure SSH access
# --------------------------------------

echo
echo "Checking SSH rule..."

MY_IP=$(curl -s https://checkip.amazonaws.com)

echo "Your public IP: $MY_IP"

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "$MY_IP/32" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "SSH rule added."
else
    echo "SSH rule already exists or could not be added."
fi

# --------------------------------------
# 7. Launch EC2 instance
# --------------------------------------

echo
echo "Launching EC2 instance..."

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=Q3-SSH}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $? -ne 0 ] || [ -z "$INSTANCE_ID" ]; then
    echo "ERROR: EC2 instance creation failed."
    exit 1
fi

echo "Instance ID: $INSTANCE_ID"

# --------------------------------------
# 8. Wait for instance
# --------------------------------------

echo
echo "Waiting for instance to become running..."

aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"

if [ $? -ne 0 ]; then
    echo "ERROR: Instance did not start."
    exit 1
fi

# --------------------------------------
# 9. Get public IP
# --------------------------------------

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "ERROR: Public IP not available."
    exit 1
fi

echo
echo "======================================"
echo "INSTANCE CREATED SUCCESSFULLY"
echo "======================================"
echo "Instance ID : $INSTANCE_ID"
echo "Public IP   : $PUBLIC_IP"
echo "Key File    : $KEY_FILE"
echo "Security SG : $SG_ID"
echo "======================================"

# --------------------------------------
# 10. SSH into instance
# --------------------------------------

echo
echo "Connecting to Ubuntu through SSH..."
echo

ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    ubuntu@"$PUBLIC_IP"
