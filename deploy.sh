#! /bin/bash
set -euo pipefail

# Function to display usage
show_help() {
    echo "Usage: $0 <bucket-name> <bucket-prefix> <admin-aws-account-id> <target-aws-account-id> <target-aws-region> <stackset-name>"
    echo
    echo "Arguments:"
    echo "  bucket-name           Name of the S3 bucket"
    echo "  bucket-prefix         Prefix/path inside the S3 bucket"
    echo "  admin-aws-account-id  Admin AWS Account ID where stackset gets created"
    echo "  target-aws-account-id Target AWS Account ID where services get provisioned"
    echo "  target-aws-region     Target AWS Region where services get provisioned"
    echo "  stackset-name         Name of the StackSet"
    echo
    echo "Options:"
    echo "  --help         Show this help message and exit"
}

# Check for --help first
if [ "${1-}" = "--help" ]; then
    show_help
    exit 0
fi

# Check number of arguments
if [ $# -ne 6 ]; then
    echo "Error: This script requires exactly six arguments !!"
    echo "Usage: $0 <bucket-name> <bucket-prefix> <admin-aws-account-id> <stackset-name>"
    exit 1
fi

# Assign arguments to variables
BUCKET_NAME="$1"
BUCKET_PREFIX="$2"
ADMIN_ACCOUNT_ID="$3"
TARGET_ACCOUNT_ID="$4"
TARGET_AWS_REGION="$5"
STACKSET_NAME="$6"

# Disable AWS CLI pager for the duration of this script
export AWS_PAGER=""

function create_stackset () {
    aws cloudformation create-stack-set \
        --stack-set-name $STACKSET_NAME \
        --template-url https://s3.amazonaws.com/$BUCKET_NAME/$BUCKET_PREFIX/main.yaml \
        --permission-model SELF_MANAGED \
        --administration-role-arn arn:aws:iam::$ADMIN_ACCOUNT_ID:role/AWSCloudFormationStackSetAdministrationRole \
        --execution-role-name AWSCloudFormationStackSetExecutionRole \
        --capabilities CAPABILITY_NAMED_IAM \
        --description "Self-managed StackSet for multiple accounts" \
        --parameters \
          ParameterKey=CFBucket,ParameterValue=$BUCKET_NAME \
          ParameterKey=CFBucketPrefix,ParameterValue=$BUCKET_PREFIX
}

function create_stack_instances () {
    aws cloudformation create-stack-instances \
        --stack-set-name $STACKSET_NAME \
        --accounts $TARGET_ACCOUNT_ID \
        --regions $TARGET_AWS_REGION \
        --parameter-overrides \
          ParameterKey=CFBucket,ParameterValue=$BUCKET_NAME \
          ParameterKey=CFBucketPrefix,ParameterValue=$BUCKET_PREFIX
}

create_stackset
create_stack_instances