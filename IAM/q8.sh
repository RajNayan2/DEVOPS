#!/bin/bash

USER_NAME="pot"

echo "Creating IAM user..."

aws iam create-user \
    --user-name "$USER_NAME"

if [ $? -ne 0 ]; then
    echo "User may already exist."
fi

echo "Attaching AdministratorAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

if [ $? -ne 0 ]; then
    echo "Failed to attach AdministratorAccess."
    exit 1
fi

echo "Attaching AmazonEC2FullAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

if [ $? -ne 0 ]; then
    echo "Failed to attach EC2 policy."
    exit 1
fi

echo "Creating access key..."

aws iam create-access-key \
    --user-name "$USER_NAME" \
    > pot-access-key.json

if [ $? -ne 0 ]; then
    echo "Failed to create access key."
    exit 1
fi

ACCESS_KEY=$(grep -o '"AccessKeyId": "[^"]*"' pot-access-key.json | head -1 | cut -d'"' -f4)

SECRET_KEY=$(grep -o '"SecretAccessKey": "[^"]*"' pot-access-key.json | head -1 | cut -d'"' -f4)

echo "Access Key created."

echo "Configuring AWS CLI..."

aws configure set aws_access_key_id "$ACCESS_KEY"
aws configure set aws_secret_access_key "$SECRET_KEY"
aws configure set region "$(aws configure get region)"

echo "AWS CLI configured."
