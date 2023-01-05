Certain features of the application, when installed with these Helm Charts, require authorized access to external systems so that they can function correctly.

Examples of this include:

* [Retrieving credentials](secrets.md#use-secrets-management-tools) from secrets management systems (e.g. AWS Secrets Manager)
* Accessing AWS managed services such as:
    * RDS authentication using IAM roles
    * AWS HealthLake
    * Accessing Amazon MSK (Managed Kafka)
    * Accessing S3 buckets
* Waiting for Kubernetes jobs to complete (i.e. during product upgrades and migration tasks)

As explained in the [Secrets Handling](secrets.md#dont-store-secrets-in-your-configuration-code) section above, passing in secrets (such as AWS Access Keys & Tokens etc) directly to your configuration is a dangerous practice. Instead we can use the mechanisms provided by various infrastructure providers to use secure methods to gain access to these external systems.

## IAM Roles For Service Accounts (IRSA)
To give the application access to AWS resources, we use [IAM Roles For Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html), also known as IRSA. This attaches AWS IAM roles to a Kubernetes `ServiceAccount` which then gets attached to the application Pods.

As a result of this, the application can access AWS services without needing to directly pass in AWS IAM User credentials.

>**Note** Currently, the Smile CDR Helm Chart only supports this integration in AWS, but support for other cloud providers will be added.

## Service Account Configuration
To use this feature, you will need to enable the Service Account and reference the IAM role that it
should be connected to. Note that the IAM role being used needs to have the appropriate Trust Policy
set up so that it can be used by your Cluster. More info and instructions are available
[here](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)

* Create an IAM role for your deployment.
    * This role will be used for any Role-based access that the application pods need,
      so name it accordingly to avoid confusion, e.g. `smilecdr-role`
    * If being used for Secrets Store CSI, ensure that it has read access to the secrets it will need to provide, and any KMS key used to encrypt them.
* Create a trust policy for the IAM role so that it can be used with IRSA. Instructions
  [here](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)
    * These instructions use the `eksctl` command which abstracts away some details into CloudFormation templates. Using something like Terraform would require different steps.

Once the IAM role is set up correctly, enable the `ServiceAccount` and reference the IAM role in the annotations in your values file like so:
```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/example-role-name
```
