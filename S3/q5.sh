#!/bin/bash

set -e

REGION="ap-south-1"

BUCKET="assignment6-q5-$(aws sts get-caller-identity --query Account --output text)-$(date +%s)"

echo "======================================"
echo "Assignment 6 - Question 5"
echo "======================================"

echo "Bucket: $BUCKET"

# --------------------------------------
# Create bucket
# --------------------------------------

echo
echo "Creating S3 bucket..."

aws s3 mb "s3://$BUCKET" --region "$REGION"

# --------------------------------------
# Create index.html
# --------------------------------------

echo
echo "Creating index.html..."

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>S3 Static Website</title>
</head>
<body>
    <h1>Hello from S3 Static Website!</h1>
    <h2>Raj Nayan</h2>
    <p>Assignment 6 - Question 5</p>
</body>
</html>
EOF

# --------------------------------------
# Upload index.html
# --------------------------------------

echo
echo "Uploading index.html..."

aws s3 cp index.html "s3://$BUCKET/"

# --------------------------------------
# Disable Block Public Access
# --------------------------------------

echo
echo "Configuring public access..."

aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# --------------------------------------
# Enable static website
# --------------------------------------

echo
echo "Enabling static website hosting..."

aws s3 website "s3://$BUCKET/" \
    --index-document index.html

# --------------------------------------
# Create bucket policy
# --------------------------------------

echo
echo "Creating bucket policy..."

cat > website-policy.json <<EOF
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

# --------------------------------------
# Attach policy
# --------------------------------------

echo
echo "Attaching bucket policy..."

aws s3api put-bucket-policy \
    --bucket "$BUCKET" \
    --policy file://website-policy.json

# --------------------------------------
# Display information
# --------------------------------------

echo
echo "======================================"
echo "WEBSITE CONFIGURATION"
echo "======================================"

aws s3api get-bucket-website \
    --bucket "$BUCKET"

WEBSITE_URL="http://$BUCKET.s3-website.$REGION.amazonaws.com"

echo
echo "======================================"
echo "STATIC WEBSITE URL"
echo "======================================"

echo "$WEBSITE_URL"

echo
echo "Testing website using curl..."

curl -I "$WEBSITE_URL"

echo
echo "======================================"
echo "Q5 COMPLETED"
echo "======================================"

echo "Open this URL in your browser:"
echo "$WEBSITE_URL"
