#!/bin/bash

ROLE_NAME="Tester-role"
POLICY_NAME="Tester-Policy"

echo "Creating trust policy..."

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

echo "Creating IAM role..."

aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json

if [ $? -ne 0 ]; then
    echo "Failed to create role."
    exit 1
fi

echo "Creating S3 read-only policy..."

cat > tester-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://tester-policy.json

if [ $? -ne 0 ]; then
    echo "Failed to create policy."
    exit 1
fi

POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

echo "Attaching policy to role..."

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

if [ $? -ne 0 ]; then
    echo "Failed to attach policy."
    exit 1
fi

echo "Role and policy created successfully."

aws iam get-role --role-name "$ROLE_NAME"

aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME"
