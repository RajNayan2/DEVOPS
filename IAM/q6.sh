#!/bin/bash

ROLE_NAME="EC2-S3-FullAccess-Role"

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "Creating role..."

aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json

if [ $? -ne 0 ]; then
    echo "Role creation failed."
    exit 1
fi

echo "Attaching EC2 full access..."

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

if [ $? -ne 0 ]; then
    echo "EC2 policy failed."
    exit 1
fi

echo "Attaching S3 full access..."

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

if [ $? -ne 0 ]; then
    echo "S3 policy failed."
    exit 1
fi

echo
echo "Role created successfully."

aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME"

