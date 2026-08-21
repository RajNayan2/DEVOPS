#!/bin/bash

REGION=$(aws configure get region)

BUCKET="assignment6-q1-$(aws sts get-caller-identity --query Account --output text)-$(date +%s)"

echo "======================================"
echo "Assignment 6 - Question 1"
echo "======================================"

echo "Bucket: $BUCKET"

echo
echo "Creating S3 bucket..."

aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

if [ $? -ne 0 ]; then
    echo "ERROR: Bucket creation failed."
    exit 1
fi

echo "Bucket created."

echo
echo "Creating files..."

echo "This is file 1." > file1.txt
echo "This is file 2." > file2.txt
echo "This is file 3." > file3.txt

echo "Uploading files..."

aws s3 cp file1.txt "s3://$BUCKET/"
if [ $? -ne 0 ]; then
    echo "ERROR: file1 upload failed."
    exit 1
fi

aws s3 cp file2.txt "s3://$BUCKET/"
if [ $? -ne 0 ]; then
    echo "ERROR: file2 upload failed."
    exit 1
fi

aws s3 cp file3.txt "s3://$BUCKET/"
if [ $? -ne 0 ]; then
    echo "ERROR: file3 upload failed."
    exit 1
fi

echo
echo "Creating bucket policy..."

cat > bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "$BUCKET" \
    --policy file://bucket-policy.json

if [ $? -ne 0 ]; then
    echo "ERROR: Bucket policy failed."
    exit 1
fi

echo
echo "======================================"
echo "Bucket contents:"
echo "======================================"

aws s3 ls "s3://$BUCKET"

echo
echo "Bucket created successfully:"
echo "$BUCKET"
