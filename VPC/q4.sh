#!/bin/bash

source vars.env

echo "Creating Internet Gateway..."

IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications \
    'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Assignment7-IGW}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "IGW ID: $IGW_ID"

echo "Attaching IGW to VPC..."

aws ec2 attach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID"

if [ $? -ne 0 ]; then
    echo "ERROR: IGW attachment failed."
    exit 1
fi

cat >> vars.env <<EOF
IGW_ID=$IGW_ID
EOF

echo
echo "Internet Gateway attached successfully."
