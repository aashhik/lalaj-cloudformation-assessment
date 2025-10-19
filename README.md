# Implementation Summary: AWS Infrastructure Provisioning and Deployment


This repository contains AWS CloudFormation templates located in the cf-templates directory.
These templates provision the core AWS infrastructure components — VPC, ECS, and ELB.

A simple Python application along with its Dockerfile is available in the app directory.

The GitHub Actions workflows for building, deploying, and automating tasks are defined under the .github/workflows directory.



To run the cloudformatiom templates, it is mandatory that you create s3 buckets and push the cloudformation templates and create required roles "AWSCloudFormationStackSetAdministrationRole" in admin account and "AWSCloudFormationStackSetExecutionRole" in target account. This is handled by prerequisites script. Also note
StackSets reside in Admin account, Stacks and exported cloudformation template values reside in target account.

Necessary role creation are taken reference from this aws cloudformation documentation
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html

PREREQUISITES SCRIPT

