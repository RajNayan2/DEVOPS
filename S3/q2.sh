#!/bin/bash

REGION=$(aws configure get region)

BUCKET="assignment6-q2-$(aws sts get-caller-identity --query Account --output text)-$(date +%s)"

echo "Bucket: $BUCKET"

echo "Creating bucket..."

aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

if [ $? -ne 0 ]; then
    echo "ERROR: Bucket creation failed."
    exit 1
fi

echo "Creating index.html..."

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Assignment 6</title>
</head>
<body>
    <h1>Hello from S3 Static Website</h1>
    <p>Assignment 6 - Question 2</p>
</body>
</html>
EOF

echo "Creating error.html..."

cat > error.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Error</title>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The requested page does not exist.</p>
</body>
</html>
EOF

echo "Uploading files..."

aws s3 cp index.html "s3://$BUCKET/"
aws s3 cp error.html "s3://$BUCKET/"

echo "Configuring website..."

aws s3 website "s3://$BUCKET/" \
    --index-document index.html \
    --error-document error.html

if [ $? -ne 0 ]; then
    echo "ERROR: Website configuration failed."
    exit 1
fi

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

echo "Applying bucket policy..."

aws s3api put-bucket-policy \
    --bucket "$BUCKET" \
    --policy file://website-policy.json

echo
echo "======================================"
echo "STATIC WEBSITE CREATED"
echo "======================================"

echo "Bucket: $BUCKET"

echo
echo "Website endpoint:"

echo "http://$BUCKET.s3-website-$REGION.amazonaws.com"

echo
echo "Files:"

aws s3 ls "s3://$BUCKET"
