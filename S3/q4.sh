#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <bucket-name>"
    exit 1
fi

BUCKET="$1"

echo "Modifying policy for bucket:"
echo "$BUCKET"

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

echo
echo "Disabling Block Public Access..."

aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

if [ $? -ne 0 ]; then
    echo "ERROR: Could not modify Block Public Access."
    exit 1
fi

echo
echo "Applying bucket policy..."

aws s3api put-bucket-policy \
    --bucket "$BUCKET" \
    --policy file://bucket-policy.json

if [ $? -ne 0 ]; then
    echo "ERROR: Policy modification failed."
    exit 1
fi

echo
echo "Policy modified successfully."

echo
echo "Current policy:"
aws s3api get-bucket-policy \
    --bucket "$BUCKET" \
    --query Policy \
    --output text
