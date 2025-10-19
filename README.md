# Implementation Summary: AWS CloudFormation
_`It is recommended to test this script in a fresh AWS environment to avoid conflicts when creating roles, services, or other resources`_

This repository contains AWS CloudFormation templates located in the `cf-templates` directory.
These templates provision the core AWS infrastructure components; VPC, ECS and ELB. A simple **Python** application along with its Dockerfile is available in the `app` directory. The **GitHub Actions** workflows for building, deploying, and automating tasks are defined under the `.github/workflows` directory. All supporting **scripts** are located in the `scripts` directory.

The cloudformation templates support multi-region deployment. Stacksets are created in Admin Account and stack instances are created in Target Account. Necessary refernce are taken from AWS documentation [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html). 

I have considered `us-east-1` as Admin AWS Region and `us-west-2` as Target AWS Region.

## What do the scripts do?

### `prerequisites.sh`

> This script installs all the necessary IAM roles and creates an S3 bucket (with a specified prefix) where the CloudFormation templates will be uploaded.  
>
> It should be executed **before running the deploy script**.  
>
> The script expects three arguments:  
> 1. `bucket_name` – Name of the S3 bucket to be created  
> 2. `bucket_prefix` – Prefix under which templates will be stored  
> 3. `admin_aws_account_id` – AWS Account ID with admin permissions  
>
> **Usage:**
> ```bash
> bash ./scripts/prerequisites.sh <your_bucket_name> <your_bucket_prefix> <your_admin_aws_account_id>
> ```
>
> **Example:**
> ```bash
> bash ./scripts/prerequisites.sh test-bucket templates 112233445566
> ```

### `deploy.sh`

