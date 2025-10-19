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

function create_update_stackset () {
    echo "Creating StackSet $STACKSET_NAME in admin account $ADMIN_ACCOUNT_ID..."
    if aws cloudformation describe-stack-set --stack-set-name "$STACKSET_NAME" >/dev/null 2>&1; then
      echo "StackSet exists. Updating template..."
      operation_id=$(aws cloudformation update-stack-set \
        --stack-set-name $STACKSET_NAME \
        --template-url https://s3.amazonaws.com/$BUCKET_NAME/$BUCKET_PREFIX/main.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --query "OperationId" \
        --output text \
        --parameters \
          ParameterKey=CFBucket,ParameterValue=$BUCKET_NAME \
          ParameterKey=CFBucketPrefix,ParameterValue=$BUCKET_PREFIX)
      if [[ $? -eq 0 ]]; then
        echo "Update initiated, Operation ID: $operation_id"
        check_status "$operation_id"
      else
        echo "Failed to perform updates !!"
      fi

    else
      echo "StackSet does not exist. Creating new StackSet..."
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
      echo ""
      echo "StackSet '$STACKSET_NAME' creation initiated."
      echo ""
      create_stack_instances
    fi
}

function create_stack_instances () {
    echo "Creating StackSet instances for account $TARGET_ACCOUNT_ID in region $TARGET_AWS_REGION..."
    echo ""

    operation_id=$(aws cloudformation create-stack-instances \
                        --stack-set-name $STACKSET_NAME \
                        --accounts $TARGET_ACCOUNT_ID \
                        --regions $TARGET_AWS_REGION \
                        --query "OperationId" \
                        --output text \
                        --parameter-overrides \
                          ParameterKey=CFBucket,ParameterValue=$BUCKET_NAME \
                          ParameterKey=CFBucketPrefix,ParameterValue=$BUCKET_PREFIX)

    echo ""
    echo "StackSet instances creation initiated with OperationId '$operation_id'..."

    check_status $operation_id
}

function check_status () {
    local operation_id=$1
    while true; do
        status=$(aws cloudformation describe-stack-set-operation \
                      --stack-set-name $STACKSET_NAME \
                      --operation-id $operation_id \
                      --query "StackSetOperation.Status" \
                      --output text)

        if [ "$status" = "SUCCEEDED" ]; then
          echo "Stack set operation succeeded. You can now test the endpoint."
          break
        elif [ "$status" = "QUEUED" ] || [ "$status" = "RUNNING" ]; then
          echo "[`date +"%a %b %d %I:%M:%S %p +0545"`] Stack set operation is still in progress. Status: $status"
          sleep 10
        else
          echo "Stack set operation failed. Status: $status"
          echo "View status in CloudFormation console."
          exit 1
        fi
    done
}

function get_alb_endpoint () {
    endpoint=$(aws elbv2 describe-load-balancers --region $TARGET_AWS_REGION | jq -r '.LoadBalancers | sort_by(.CreatedTime) | last(.[]).DNSName')
    echo "Your AWS ALB endpoint is: $endpoint"
    echo "alb-endpoint=$endpoint" >> $GITHUB_OUTPUT
}

create_update_stackset
get_alb_endpoint