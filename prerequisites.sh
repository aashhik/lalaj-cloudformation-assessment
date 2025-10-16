#! /bin/bash
set -euo pipefail

BUCKET_NAME="$1"
TEMPLATE_DIR="./cf-templates"

# Disable AWS CLI pager for the duration of this script
export AWS_PAGER=""

if [ $# -lt 1 ]; then
    echo "Error: This script requires exactly one argument !!"
    echo "Usage: $0 <bucket-name>"
    exit 1
fi

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
    aws cloudformation create-stack \
        --stack-name createCloudFormationStackSetAdministrationRole \
        --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml \
        --capabilities CAPABILITY_NAMED_IAM 
}

function create_cf_stackset_execution_role () {
    aws cloudformation create-stack \
        --stack-name createCloudFormationStackSetExecutionRole \
        --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
        --parameters ParameterKey=AdministratorAccountId,ParameterValue=144947567756 \
        --capabilities CAPABILITY_NAMED_IAM
}

create_s3_bucket
create_cf_stackset_administration_role
create_cf_stackset_execution_role