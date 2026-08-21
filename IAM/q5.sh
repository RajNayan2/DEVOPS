#!/bin/bash

echo "========== IAM USERS =========="

USERS=$(aws iam list-users \
    --query 'Users[].UserName' \
    --output text)

for USER in $USERS
do
    echo
    echo "User: $USER"

    ARN=$(aws iam get-user \
        --user-name "$USER" \
        --query 'User.Arn' \
        --output text)

    echo "ARN: $ARN"

    echo "Attached Policies:"

    aws iam list-attached-user-policies \
        --user-name "$USER" \
        --query 'AttachedPolicies[].PolicyName' \
        --output table
done
