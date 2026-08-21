#!/bin/bash

REGION=$(aws configure get region)

RANDOM_VALUE=$(date +%s%N | sha256sum | cut -c1-12)

BUCKET="assignment6-random-$RANDOM_VALUE"

echo "Generated bucket name:"
echo "$BUCKET"

echo
echo "Creating bucket..."

aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

if [ $? -ne 0 ]; then
    echo "ERROR: Bucket creation failed."
    exit 1
fi

echo
echo "Retrieving bucket name..."

aws s3api list-buckets \
    --query "Buckets[?Name=='$BUCKET'].Name" \
    --output text

echo
echo "Creating script file..."

cat > test-script.sh <<EOF
#!/bin/bash

echo "This script was uploaded to S3."
echo "Assignment 6 - Question 3"
EOF

echo
echo "Uploading script..."

aws s3 cp test-script.sh "s3://$BUCKET/"

if [ $? -ne 0 ]; then
    echo "ERROR: Upload failed."
    exit 1
fi

echo
echo "Bucket contents:"

aws s3 ls "s3://$BUCKET"

echo
echo "Deleting bucket contents..."

aws s3 rm "s3://$BUCKET" \
    --recursive

echo
echo "Deleting bucket..."

aws s3api delete-bucket \
    --bucket "$BUCKET" \
    --region "$REGION"

if [ $? -ne 0 ]; then
    echo "ERROR: Bucket deletion failed."
    exit 1
fi

echo
echo "Bucket deleted successfully."
