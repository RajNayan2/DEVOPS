#!/bin/bash

source vars.env

echo "Creating public route table..."

PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications \
    'ResourceType=route-table,Tags=[{Key=Name,Value=Assignment7-Public-RT}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Route Table: $PUBLIC_RT_ID"

echo "Creating default route..."

aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID"

echo "Associating route table with public subnet..."

ASSOCIATION_ID=$(aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_RT_ID" \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --query 'AssociationId' \
    --output text)

cat >> vars.env <<EOF
PUBLIC_RT_ID=$PUBLIC_RT_ID
PUBLIC_RT_ASSOCIATION_ID=$ASSOCIATION_ID
EOF

echo
echo "======================================"
echo "ROUTE TABLE VERIFICATION"
echo "======================================"

aws ec2 describe-route-tables \
    --route-table-ids "$PUBLIC_RT_ID" \
    --query 'RouteTables[0].[RouteTableId,Routes[?DestinationCidrBlock==`0.0.0.0/0`].DestinationCidrBlock|[0]]' \
    --output table
