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
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "S3 bucket '$BUCKET_NAME' already exists. Skipping creation."
        echo ""
        echo "Uploading Cloudformation templates to $BUCKET_NAME S3 bucket..."
        upload_templates
        echo "Upload Completed !!"
        echo ""

    else
        echo "Creating S3 Bucket $BUCKET_NAME with prefix $BUCKET_PREFIX..."
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --region us-east-1
        echo "Created !!"
        echo ""
        echo "Uploading Cloudformation templates to $BUCKET_NAME S3 bucket..."
        upload_templates
        echo "Upload Completed !!"
        echo ""
    fi
} 

function upload_templates () {
    for file in `ls $TEMPLATE_DIR/*.yaml`; do
        aws s3 cp "$file" "s3://$BUCKET_NAME/$BUCKET_PREFIX/$(basename "$file")"
    done
}

function create_cf_stackset_administration_role () {
    if ! aws iam list-roles --query "Roles[].RoleName" --output text | grep -q AWSCloudFormationStackSetAdministrationRole; then
        echo "Creating CloudFormation stack that creates Cloudformation Administration Role"
        aws cloudformation create-stack\
            --stack-name createCloudFormationStackSetAdministrationRole \
            --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml \
            --capabilities CAPABILITY_NAMED_IAM
        aws cloudformation wait stack-create-complete \
            --stack-name createCloudFormationStackSetAdministrationRole
        echo "Stack creation complete !!"
    else
        echo "CloudFormation Administration Role already exists[SKIPPED]."
    fi
}

function create_cf_stackset_execution_role () {
    local role_name="AWSCloudFormationStackSetExecutionRole"
    if ! aws iam list-roles --query "Roles[].RoleName" --output text | grep -q AWSCloudFormationStackSetExecutionRole; then
        echo "Creating CloudFormation stack that creates Cloudformation Execution Role"
        aws cloudformation create-stack \
            --stack-name createCloudFormationStackSetExecutionRole \
            --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
            --parameters ParameterKey=AdministratorAccountId,ParameterValue=$ADMIN_ACCOUNT_ID \
            --capabilities CAPABILITY_NAMED_IAM
        aws cloudformation wait stack-create-complete \
            --stack-name createCloudFormationStackSetExecutionRole
        echo "Stack creation complete. Proceeding to attach minimal policy..."
        echo "Detaching all managed policies from role: $role_name"
        policy_arn=$(aws iam list-attached-role-policies \
                        --role-name AWSCloudFormationStackSetExecutionRole \
                        --query "AttachedPolicies[*].PolicyArn" \
                        --output text)

        aws iam detach-role-policy \
            --role-name AWSCloudFormationStackSetExecutionRole \
            --policy-arn $policy_arn
        
        add_minimal_policy
    else
        echo "CloudFormation Execution Role already exists[SKIPPED]."
        add_minimal_policy
    fi
}

function add_minimal_policy () {
    local policy_file="policy.json"
    local policy_name="CFStackSetExecutionMinimalPolicy"
    echo ""
    echo "Generating minimal policy for AWSCloudFormationStackSetExecutionRole IAM Role"
    cat > "$policy_file" <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "autoscaling:*",
                "ecs:*",
                "elasticloadbalancing:*",
                "cloudformation:*",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DescribeParameters",
                "logs:*",
                "iam:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/$BUCKET_PREFIX/*"
            ]
        }
    ]
}
EOF

    echo "Attaching minimal inline policy: $policy_name"
    aws iam put-role-policy \
        --role-name $role_name \
        --policy-name $policy_name \
        --policy-document file://$policy_file
    echo ""
    echo "Minimal inline policy attached successfully to $role_name !!"
}

create_s3_bucket
create_cf_stackset_administration_role
create_cf_stackset_execution_role