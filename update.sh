#! /bin/bash

set -euo pipefail

BUCKET_NAME="$1"
BUCKET_PREFIX="$2"
ADMIN_ACCOUNT_ID="$3"
STACKSET_NAME="$4"

export AWS_PAGER=""

function update_stackset () {
    aws cloudformation update-stack-set \
        --stack-set-name $STACKSET_NAME \
        --template-url https://s3.amazonaws.com/$BUCKET_NAME/$BUCKET_PREFIX/main.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
          ParameterKey=CFBucket,ParameterValue=$BUCKET_NAME \
          ParameterKey=CFBucketPrefix,ParameterValue=$BUCKET_PREFIX
}

update_stackset