#!/bin/bash

GROUP_NAME="testing"
USER1="Test1"
USER2="Test2"
ROLE_NAME="Tester-role"

echo "Creating users..."

aws iam create-user --user-name "$USER1"
if [ $? -ne 0 ]; then
    echo "Test1 creation failed."
fi

aws iam create-user --user-name "$USER2"
if [ $? -ne 0 ]; then
    echo "Test2 creation failed."
fi

echo "Creating group..."

aws iam create-group --group-name "$GROUP_NAME"

if [ $? -ne 0 ]; then
    echo "Group may already exist."
fi

echo "Adding users to group..."

aws iam add-user-to-group \
    --group-name "$GROUP_NAME" \
    --user-name "$USER1"

aws iam add-user-to-group \
    --group-name "$GROUP_NAME" \
    --user-name "$USER2"

echo "Getting role policy..."

POLICY_ARN=$(aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME" \
    --query 'AttachedPolicies[0].PolicyArn' \
    --output text)

echo "Policy ARN: $POLICY_ARN"

echo "Attaching policy to group..."

aws iam attach-group-policy \
    --group-name "$GROUP_NAME" \
    --policy-arn "$POLICY_ARN"

echo "Users in group:"

aws iam get-group --group-name "$GROUP_NAME"
