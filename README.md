# lalas-cloudformation-assessment

##

This repo consists of cloud formation templates and resides under cf-templates. These templates provisions vpc, ecs and elb.


To run the cloudformatiom templates, it is mandatory that you create s3 buckets and push the cloudformation templates and create required roles "AWSCloudFormationStackSetAdministrationRole" in admin account and "AWSCloudFormationStackSetExecutionRole" in target account. This is handled by prerequisites script. Also note
StackSets reside in Admin account, Stacks and exported cloudformation template values reside in target account.

Necessary role creation are taken reference from this aws cloudformation documentation
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html

PREREQUISITES SCRIPT

