#!/bin/bash

CSV_FILE="users.csv"
LOG_FILE="provision.log"
ERROR_FILE="errors.log"

> "$LOG_FILE"
> "$ERROR_FILE"

echo "========== IAM PROVISIONING ==========" | tee -a "$LOG_FILE"

# Remove Windows line endings and trailing whitespace
sed -i 's/\r$//; s/[[:space:]]*$//' "$CSV_FILE"

# Count records excluding header
TOTAL=$(tail -n +2 "$CSV_FILE" | grep -v '^$' | wc -l)

echo "Processing $TOTAL users..." | tee -a "$LOG_FILE"

VALID_FILE=$(mktemp)
REJECTED_FILE=$(mktemp)

echo "========== VALIDATION =========="

# Read CSV line by line
tail -n +2 "$CSV_FILE" | while IFS=',' read -r username department access_level
do

    # Trim spaces
    username=$(echo "$username" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    department=$(echo "$department" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    access_level=$(echo "$access_level" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Username validation
    if ! echo "$username" | grep -Eq '^[a-z]+\.[a-z]+$'
    then
        echo "REJECTED: $username - invalid username" | tee -a "$LOG_FILE"
        echo "$username | invalid username" >> "$REJECTED_FILE"
        continue
    fi

    # Department validation
    if [ -z "$department" ]
    then
        echo "REJECTED: $username - missing department" | tee -a "$LOG_FILE"
        echo "$username | missing department" >> "$REJECTED_FILE"
        continue
    fi

    # Access level validation using grep
    if ! echo "$access_level" | grep -Eq '^(readonly|poweruser|admin)$'
    then
        echo "REJECTED: $username - invalid access_level" | tee -a "$LOG_FILE"
        echo "$username | invalid access_level" >> "$REJECTED_FILE"
        continue
    fi

    echo "$username,$department,$access_level" >> "$VALID_FILE"

done

VALID_COUNT=$(wc -l < "$VALID_FILE")
REJECTED_COUNT=$(wc -l < "$REJECTED_FILE")

echo
echo "Valid rows: $VALID_COUNT"
echo "Rejected rows: $REJECTED_COUNT"

echo
echo "========== VALID USERS =========="

cat "$VALID_FILE"

echo
echo "========== REJECTED USERS =========="

cat "$REJECTED_FILE"

# Create custom admin policy
cat > custom-admin-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
EOF

ACCOUNT_ID=$(aws sts get-caller-identity \
    --query Account \
    --output text)

if [ $? -ne 0 ]
then
    echo "ERROR: Unable to get AWS account ID" >> "$ERROR_FILE"
    exit 1
fi

CUSTOM_POLICY_NAME="DepartmentAdminPolicy"

CUSTOM_POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$CUSTOM_POLICY_NAME"

# Check whether custom policy exists
aws iam get-policy \
    --policy-arn "$CUSTOM_POLICY_ARN" >/dev/null 2>&1

if [ $? -ne 0 ]
then

    aws iam create-policy \
        --policy-name "$CUSTOM_POLICY_NAME" \
        --policy-document file://custom-admin-policy.json

    if [ $? -ne 0 ]
    then
        echo "ERROR: Failed to create custom policy" | tee -a "$ERROR_FILE"
    else
        echo "Created custom policy" | tee -a "$LOG_FILE"
    fi
else
    echo "Custom policy already exists" | tee -a "$LOG_FILE"
fi

echo
echo "========== PROCESSING USERS =========="

while IFS=',' read -r username department access_level
do

    echo
    echo "Processing: $username"

    # Check if user already exists
    aws iam get-user \
        --user-name "$username" >/dev/null 2>&1

    if [ $? -eq 0 ]
    then
        echo "SKIPPED: already exists - $username" | tee -a "$LOG_FILE"
        continue
    fi

    # Create IAM user
    aws iam create-user \
        --user-name "$username"

    if [ $? -ne 0 ]
    then
        echo "FAILED: user creation - $username" | tee -a "$LOG_FILE"
        echo "ERROR: Failed to create $username" >> "$ERROR_FILE"
        continue
    fi

    echo "SUCCESS: created $username" | tee -a "$LOG_FILE"

    # Select policy
    case "$access_level" in

        readonly)
            POLICY_ARN="arn:aws:iam::aws:policy/ReadOnlyAccess"
            ;;

        poweruser)
            POLICY_ARN="arn:aws:iam::aws:policy/PowerUserAccess"
            ;;

        admin)
            POLICY_ARN="$CUSTOM_POLICY_ARN"
            ;;

    esac

    # Attach policy
    aws iam attach-user-policy \
        --user-name "$username" \
        --policy-arn "$POLICY_ARN"

    if [ $? -ne 0 ]
    then
        echo "FAILED: policy attachment - $username" | tee -a "$LOG_FILE"
        echo "ERROR: Failed to attach policy to $username" >> "$ERROR_FILE"
        continue
    fi

    echo "SUCCESS: policy attached - $username | $access_level" | tee -a "$LOG_FILE"

done < "$VALID_FILE"

echo
echo "========== FINAL REPORT =========="

echo "Total users processed : $TOTAL"
echo "Valid users           : $VALID_COUNT"
echo "Rejected users        : $REJECTED_COUNT"

SUCCESS_COUNT=$(grep -c "SUCCESS: created" "$LOG_FILE")
FAILURE_COUNT=$(grep -c "FAILED:" "$LOG_FILE")

echo "Successful creations  : $SUCCESS_COUNT"
echo "Failures              : $FAILURE_COUNT"

echo
echo "========== POLICY TABLE =========="

printf "%-20s | %-40s\n" "USERNAME" "POLICY"
printf "%-20s-+-%-40s\n" "--------------------" "----------------------------------------"

while IFS=',' read -r username department access_level
do

    case "$access_level" in

        readonly)
            POLICY="ReadOnlyAccess"
            ;;

        poweruser)
            POLICY="PowerUserAccess"
            ;;

        admin)
            POLICY="DepartmentAdminPolicy"
            ;;

    esac

    printf "%-20s | %-40s\n" "$username" "$POLICY"

done < "$VALID_FILE"

echo
echo "Log file    : $LOG_FILE"
echo "Error file  : $ERROR_FILE"

rm -f "$VALID_FILE" "$REJECTED_FILE"
