#! /bin/bash
set -euo pipefail

# Function to display usage
show_help() {
    echo "Usage: $0 <bucket-name> <bucket-prefix> <admin_aws_account_id>"
    echo
    echo "Arguments:"
    echo "  bucket-name           Name of the S3 bucket"
    echo "  bucket-prefix         Prefix/path inside the S3 bucket"
    echo "  admin_aws_account_id  Admin AWS Account ID where stackset gets created"
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
if [ $# -ne 3 ]; then
    echo "Error: This script requires exactly three arguments !!"
    echo "Usage: $0 <bucket-name> <bucket-prefix> <admin_aws_account_id>"
    exit 1
fi

# Assign arguments to variables
BUCKET_NAME="$1"
BUCKET_PREFIX="$2"
ADMIN_ACCOUNT_ID="$3"
TEMPLATE_DIR="./cf-templates"

# Disable AWS CLI pager for the duration of this script
export AWS_PAGER=""

function create_s3_bucket () {
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region us-east-1

    upload_templates
} 

function upload_templates () {
    for file in `ls $TEMPLATE_DIR/*.yaml`; do
        aws s3 cp "$file" "s3://$BUCKET_NAME/cf-templates/$(basename "$file")"
    done
}

function create_cf_stackset_administration_role () {
    if ! aws iam list-roles --query "Roles[].RoleName" --output text | grep -q AWSCloudFormationStackSetAdministrationRole; then
        echo "Role not found. Creating CloudFormation stack that creates Cloudformation Administration Role"
        aws cloudformation create-stack \
            --stack-name createCloudFormationStackSetAdministrationRole \
            --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml \
            --capabilities CAPABILITY_NAMED_IAM
    else
        echo "CloudFormation Administration Role already exists."
    fi
}

function create_cf_stackset_execution_role () {
    if ! aws iam list-roles --query "Roles[].RoleName" --output text | grep -q AWSCloudFormationStackSetExecutionRole; then
        echo "Role not found. Creating CloudFormation stack that creates Cloudformation Execution Role"
        aws cloudformation create-stack \
            --stack-name createCloudFormationStackSetExecutionRole \
            --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
            --parameters ParameterKey=AdministratorAccountId,ParameterValue=$ADMIN_ACCOUNT_ID \
            --capabilities CAPABILITY_NAMED_IAM
    else
        echo "CloudFormation Execution Role already exists."
    fi
}

create_s3_bucket
create_cf_stackset_administration_role
create_cf_stackset_execution_role