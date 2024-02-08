# Smile CDR Dependencies Terraform Module

Terraform module which creates AWS resources required for a Kubernetes based install od Smile CDR.

## Available Features

- Creation of RDS instances
- Creation of IAM Role to work with IRSA

## Usage

```hcl
module "smile-cdr-dependencies" {
  source = "git::https://gitlab.com/smilecdr-public/smile-dh-helm-charts//src/main/terraform/smile-cdr-deps?ref=pre-release"
}
```

## Examples

- [Default](examples/default): Basic usage of this Terraform Module
