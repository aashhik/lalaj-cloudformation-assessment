#!/bin/bash
set -euo pipefail

# Add your value here
BUCKET_NAME="my-bucket"
BUCKET_PREFIX="templates"
ADMIN_ACCOUNT_ID="112233445566"
TARGET_ACCOUNT_ID="112233445566"
TARGET_REGION="us-west-2"
STACKSET_NAME="my-stackset"

# Run prerequisites script
echo "Running prerequisites..."
bash prerequisites.sh "$BUCKET_NAME" "$BUCKET_PREFIX" "$ADMIN_ACCOUNT_ID"


# Deploy CloudFormation StackSet
echo "Deploying StackSet..."
bash deploy.sh "$BUCKET_NAME" "$BUCKET_PREFIX" "$ADMIN_ACCOUNT_ID" "$TARGET_ACCOUNT_ID" "$TARGET_REGION" "$STACKSET_NAME"

echo "Deployment completed successfully!"