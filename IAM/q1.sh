#!/bin/bash

USER_NAME="Test"

echo "Checking IAM user: $USER_NAME"

aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "User $USER_NAME already exists."
else
    echo "Creating IAM user: $USER_NAME"

    aws iam create-user --user-name "$USER_NAME"

    if [ $? -ne 0 ]; then
        echo "Failed to create user."
        exit 1
    fi

    echo "User created successfully."
fi

echo "Attaching AdministratorAccess..."

aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

if [ $? -ne 0 ]; then
    echo "Failed to attach AdministratorAccess."
    exit 1
fi

echo "Administrator access attached successfully."

echo
echo "========== USER REPORT =========="

aws iam get-user \
    --user-name "$USER_NAME"

echo
echo "========== ATTACHED POLICIES =========="

aws iam list-attached-user-policies \
    --user-name "$USER_NAME"
