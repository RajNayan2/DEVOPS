#!/bin/bash

VPC_CIDR="10.0.0.0/16"

echo "Creating VPC..."

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --tag-specifications \
    'ResourceType=vpc,Tags=[{Key=Name,Value=Assignment7-VPC-Q2}]' \
    --query 'Vpc.VpcId' \
    --output text)

if [ $? -ne 0 ]; then
    echo "ERROR: VPC creation failed."
    exit 1
fi

echo "VPC created: $VPC_ID"

cat > vars.env <<EOF
VPC_ID=$VPC_ID
EOF

echo
echo "vars.env:"
cat vars.env

echo
echo "Verifying VPC..."

aws ec2 describe-vpcs \
    --vpc-ids "$VPC_ID" \
    --query 'Vpcs[0].[VpcId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' \
    --output table
