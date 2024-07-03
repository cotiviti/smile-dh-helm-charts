# Terraform S3 State Bootstrapping

Terraform State shoudl not be stored locally on your workstation. If you do not already have a Terraform Remote State solution in place, you can easily set it up on AWS using an S3 bucket and a DynamoDB table.

When using Terraform itself to deploy these resources, you end up with a 'chicken and egg' problem. i.e. Where do you store the state files for THESE resources.

This CDK project can be used to create the required resources to use AWS S3 buckets and a DynamoDB table for the Terraform State backend. As CDK uses the native AWS CloudFormation service to manage state natively in the AWS account, this solves the 'chicken and egg' problem.

To use this CDK project, do the following.
>**Note:** Reference commands are listed further down.

* Install CDK + Typescript
* Install the `cdk-terraform-state-backend` CDK Component
* Ensure that you have suitable permissions on the AWS cli and confirm that you are
authenticated against the correct account, using `aws sts get-caller-identity`
* Bootstrap the CDK environment for this account if it has not been done already.
* Deploy this project

For this example CDK project. the AWS account and region are automatically chosen based on the current
AWS CLI profile.

After deploying, a bucket will be created in the account like so:

`terraform-state-backend-<account_id>-<region>`

The Terraform Backend can then be configured accordingly:

```
terraform {

  # Uncomment and update settings to use S3 backend for Terraform state
  backend "s3" {
    bucket = "terraform-state-backend-<account_id>-<region>"
    dynamodb_table = "terraform-state-backend"
    key = "eks/clusters/MyClusterName"
    region = "<region>"
  }
}
```

## Useful commands

* `npm install`  Install dependencies
* `cdk bootstrap aws://0123456789010/us-east-1` Bootstrap the CDK environment in specified AWS Account
* `cdk deploy`      Deploy stack
* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template
