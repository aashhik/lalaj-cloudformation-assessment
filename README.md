# Implementation Summary: AWS Infrastructure Provisioning and Deployment

`This script is tested in fresh AWS environment so there would be no conflics regarding the creation of roles`

>This repository contains AWS CloudFormation templates located in the `cf-templates` directory.
These templates provision the core AWS infrastructure components; VPC, ECS and ELB. A simple **Python** application along with its Dockerfile is available in the `app` directory. The **GitHub Actions** workflows for building, deploying, and automating tasks are defined under the `.github/workflows` directory. All supporting **scripts** are located in the `scripts` directory.
>

## What does scripts do?

### prerequisites.sh
> This scripts installs all necessary roles and s3 buckets with prefix where we will be copying cloudformation templates in