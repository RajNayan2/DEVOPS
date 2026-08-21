#!/bin/bash

USER_NAME="YOUR_REGISTRATION_NUMBER"

echo "Creating IAM user: $USER_NAME"

aws iam create-user --user-name "$USER_NAME"

if [ $? -ne 0 ]; then
    echo "User creation failed."
    exit 1
fi

echo "Attaching AdministratorAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

if [ $? -ne 0 ]; then
    echo "AdministratorAccess failed."
fi

echo "Attaching AmazonEC2FullAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

if [ $? -ne 0 ]; then
    echo "EC2 policy failed."
fi

echo "Attaching AmazonS3FullAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

if [ $? -ne 0 ]; then
    echo "S3 policy failed."
fi

echo
echo "========== USER REPORT =========="

aws iam get-user \
    --user-name "$USER_NAME"

echo
echo "========== ATTACHED POLICIES =========="

aws iam list-attached-user-policies \
    --user-name "$USER_NAME"

echo
echo "========== USER ARN =========="

aws iam get-user \
    --user-name "$USER_NAME" \
    --query 'User.Arn' \
    --output text	
