# Secrets Handling
Secrets management can be a hard subject to get right. Unfortunately, the ***easy*** way quite often lacks basic security considerations and can lead to unexpected data compromises.

At Smile Digital Health, we take security very seriously, so we have designed these Helm Charts in a way that follows secure practices, to reduce the likelihood of such compromises.

## Secrets Best Practices
### Use Temporary Credentials
As a general security best-practice, avoid using long-lived credentials where possible. This practice can be achieved when using cloud based environments, using their underlying cloud provider technologies.

For example, on AWS the best practice is to [use temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#bp-workloads-use-roles) using IAM Instance Profiles and [IAM Roles For Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) (IRSA).

### Don't Store Secrets in your Configuration Code
There are some scenarios where long-lived secret values still need to be used in your deployment. These secret values may be required at the Kubernetes level, such as when pulling container images from private repositories, or at the application level, such as when connecting to databases or other external systems that require authentication.

While it may simplify provisioning and automation by including secrets (such as passwords, certificates or API keys) in code, it is widely accepted as a bad practice as it can compromise the security of your system by increasing the attack surface area.

If the code containing the secrets is somehow leaked, protected resources may be compromised. Additionally, if the code is shared among multiple team members, it can be difficult to control who has access to the secrets and when they were last rotated.

### Use Secrets Management Tools
It is recommended to use a secrets management tool to store and manage secrets separately from code. This way, secrets can easily be rotated and access can be tightly controlled.

Various secrets management tools are available that allow you to store secrets in a secure, centralized location and control access to them through granular RBAC configurations. This helps ensure that only authorized systems have access to sensitive information, helping to prevent accidental disclosure of secret material and PHI.

## Supported Secret Mechanisms
These Helm Charts support the following three methods to reference secrets.

| Method | Security | Difficulty | Notes |
|--------|----------|------------|-------|
|IAM Auth for AWS RDS|Highest|Hard|Recommended method for connecting to AWS RDS databases.|
|Secrets Store CSI|High|Hard|Recommended method where long-lived credentials are required. You will need the SSCSI driver, an appropriate SSCSI provider, A secrets vault Secret and any IAM roles configured to access the secret|
|Kubernetes Secret|Medium|Medium|Need to manually set up Kubernetes Secret|

### Secrets Store CSI Driver
Using the [Secrets Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)(SSCSI) is the preferred method to configure secrets in these Helm Charts.

This mechanism is recommended by AWS, Azure and Google to retrieve secrets from their respective secret management services. It also has support for other Secret Vault providers such as HashiCorp Vault.

Currently, the Smile CDR Helm Chart only supports the Secrets Store CSI Driver with the AWS Secrets Manager provider.

In order to use this method of configuring secrets, there are some pre-requisites that need to be in place.

* Create your secret in AWS Secrets Manager.
    * The secret data should be in a suitabe structured JSON format, as described
    [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html)
    * Your secret should be encrypted using an AWS CMK ([Customer Managed Key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk)).
* Create an IAM role and trust policy.
* Enable the `ServiceAccount` and reference the IAM role in the annotations.
* See the [Service Account Configuration section](../serviceaccount.md) for more details on setting this up.

>**Note:** The process of creating secrets and configuring access to them can be greatly simplified if using the supporting [dependencies Terraform Module](../../terraform/smilecdrdeps/index.md)

### Kubernetes Secret

Alternatively, you can create the Kubernetes `Secret` object through some other method. Although it avoids the secret data being included in your code, it does not provide a centralized location to store, manage and control access to secrets.

Be wary of including custom Kubernetes `Secret` manifests alongside your Helm values files. Although this is a convenient way to provision them, it just re-introduces the problem of secrets residing in your code, which should be avoided.

### Values File (Retired)

~~Finally, we do support providing credentials in the values file itself. This is not a recommended solution and really only intended as a ***quickstart*** method to allow for quick experimentation with the charts.~~

>**NOTE:** Support for this feature has now been removed from the Helm Chart. This section remains as a reference and an explanation for why it is not an option. Although using this feature allowed for a quick setup of an environment, it encouraged users to use bad security practice in higher environments.
