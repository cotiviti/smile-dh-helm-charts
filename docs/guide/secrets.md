# Secrets Handling
Secrets management can be a hard subject to get right. Unfortunately, the ***easy*** way quite often lacks basic security considerations and can lead to unexpected data compromises.

At Smile Digital Health, we take security very seriously, so we have designed these Helm Charts in a way that follows best practices, to reduce the likelihood of such compromises.

## Secrets Best Practices
### Use Temporary Credentials
Where possible, use of long-lived credentials should be avoided. This is a general best-practice for cloud based environments that typically relies on underlying cloud provider technologies.

For example, on AWS the best practice is to [use temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#bp-workloads-use-roles) using IAM Instance Profiles and [IAM Roles For Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) (IRSA).

### Don't Store Secrets in your Configuration Code
There are some scenarios where long-lived secret values still need to be used in this Helm Chart. These secret values may be required at the Kubernetes level, such as when pulling container images from private repositories, or at the application level, such as when connecting to databases or other external systems that require authentication.

While it is easy to create secrets (such as passwords or API keys) in code, to simplify provisioning and automation, it is generally considered bad practice to do so because it can compromise the security of your system.

If the code containing the secrets is somehow leaked, protected resources may be compromised. Additionally, if the code is shared among multiple team members, it can be difficult to control who has access to the secrets and when they were last rotated.

### Use Secrets Management Tools
It is recommended to use a secrets management tool to store and manage secrets separately from code. This way, secrets can easily be rotated and access can be tightly controlled.

Various secrets management tools are available that allow you to store secrets in a secure, centralized location and control access to them through granular permissions. This helps ensure that only authorized personnel have access to sensitive information and helps prevent accidental disclosure of secrets.

## Supported Secret Mechanisms
These Helm Charts support the following three methods to reference secrets.

| Method | Security | Difficulty | Notes |
|--------|----------|------------|-------|
|Secrets Store CSI|High|Hardest|Recommended method. You will need the SSCSI driver, an appropriate SSCSI provider, A secrets vault Secret and any IAM roles configured to access the secret|
|Kubernetes Secret|Medium|Medium|Need to manually set up Kubernetes Secret|
|Values File|Low|Easiest|K8s secret created by chart. Password is in your code (Bad)|

### Secrets Store CSI Driver
Using the [Secrets Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)(SSCSI) is the preferred method to configure secrets in these Helm Charts.

This mechanism is recommended by AWS, Azure and Google to retrieve secrets from their respective secret management services. It also has support for other Secret Vault providers such as HashiCorp Vault.

Currently, the Smile CDR Helm Chart only supports the Secrets Store CSI Driver with the AWS Secrets Manager provider.

Before you can use this method in your configuration, you will need to set up some pre-requisites.

* Create your secret in AWS Secrets Manager.
    * The secret data should be in a suitabe structured Json format, as described
    [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html)
    * Your secret should be encrypted using an AWS CMK ([Customer Managed Key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk)).
* Create an IAM role and trust policy.
* Enable the `ServiceAccount` and reference the IAM role in the annotations.
* See the [Service Account Configuration section](serviceaccount.md) for more details on setting this up.

The way the secret is configured in your `values` file differs depending on the section of configuration. Please refer to the individual sections below for details:

* [Image Repository Credentials](helm-repo.md#configuring-repo-credentials-using-secrets-store-csi-driver)
* [Database Credentials](smilecdr/database.md#example-secret-configuration)
* [Smile CDR License](smilecdr/cdr-license.md)

>**Note:** At this time, there is no support for adding arbitrary secrets to the environment using this mechanism. An `extraSecrets` configuration will be added in a future Helm Chart release to enable this. In the meantime, if you need to inject secrets into a JavaScript callback script, you can retrieve secrets directly from AWS SecretsManager by following the instructions in the [Use Secrets In JavaScript Execution Environment](#use-secrets-in-javascript-execution-environment) section.

### Kubernetes Secret

Alternatively, you can create the Kubernetes `Secret` object through some other method. Although it avoids the secret data being included in your code, it does not provide a centralized location to store, manage and controll access to secrets.

Be wary of including custom Kubernetes `Secret` manifests alongside your Helm values files. Although this is a convenient way to provision them, it just re-introduces the problem of secrets residing in your code, which should be avoided.

### Values File

Finally, we do support providing credentials in the values file itself. This is not a recommended solution and really only intended as a ***quickstart*** method to allow for quick experimentation with the charts.

>**WARNING:** This is not a recommended approach as it is insecure. This functionality may be removed in future versions of the charts as it can lead to insecure habits/practices forming.

## Use Secrets In JavaScript Execution Environment

If you are using a [callback function](https://smilecdr.com/docs/javascript_execution_environment/introduction.html) in your Smile CDR configuration, there are 2 ways you could use secrets from the script.

1. Use the AWS Java SDK to retrieve secrets from AWS Secrets Manager, directly within your script.
2. Use the Secrets Store CSI driver to retrieve and mount the secrets inside the pod.

There are benefits and drawbacks to each of these mechanisms, however at this time only the first option is available.

### Retrieve AWS Secrets Manager Secrets From Callback Script

You can use the below function to retrieve secrets directly from AWS Secrets Manager using the included AWS Java SDK and the [graal-js](https://www.graalvm.org/latest/reference-manual/js/) engine's Java compatibility layer.

1. #### IAM configuration
Ensure that the IAM role used by your Smile CDR service account has sufficient permissions to retrieve the secret. It should have the following statement within its IAM policy.
```json
{
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:secretsmanager:<region>:123456789010:secret:secretName"
    }
  ],
  "Version": "2012-10-17"
}
```

2. #### Define Function
Define the following re-usable `getSecretsManagerSecretV1()` function in your JavaScript callback function:
```js
function getSecretsManagerSecretV1 (secretName,secretKey,awsRegion='us-east-1') {
  let DefaultAWSCredentialsProviderChain = Java.type('com.amazonaws.auth.DefaultAWSCredentialsProviderChain');
  let AWSSecretsManagerClientBuilder = Java.type('com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder');
  let GetSecretValueRequest = Java.type('com.amazonaws.services.secretsmanager.model.GetSecretValueRequest');
  let Regions = Java.type('com.amazonaws.regions.Regions');


  let credentialsProvider = new DefaultAWSCredentialsProviderChain();
  let secretsManagerClient = AWSSecretsManagerClientBuilder.standard()
    .withCredentials(credentialsProvider)
    .withRegion(Regions.fromName(awsRegion))
    .build();
  let secretValueRequest = new GetSecretValueRequest().withSecretId(secretName);
  let secretValue = secretsManagerClient.getSecretValue(secretValueRequest);
  if (secretKey) {
    // Just return the value for the specified secret key
    return JSON.parse(secretValue.getSecretString())[secretKey];
  } else {
    // Return the entire secret string
    return JSON.parse(secretValue.getSecretString());
  }
}
```
**Note:** Currently this is using the [AWS Java SDK Version 1](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/welcome.html) which is being [deprecated](https://aws.amazon.com/blogs/developer/announcing-end-of-support-for-aws-sdk-for-java-v1-x-on-december-31-2025/). Support for the [AWS Java SDK Version 2](https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/home.html) will be added in a future version of Smile CDR.

3. #### Environment Variables
Set some appropriate environment variables using the [extraEnvVars](./smilecdr/envvars.md#passing-extra-environment-variables) Helm Chart feature.
```yaml
extraEnvVars:
- name: JS_EXAMPLE_SECRET_NAME
  value: nameOrFullARNOfSecretsManagerSecret
- name: JS_EXAMPLE_SECRET_KEY
  value: keyname
# Optional: Function defaults to `us-east-1`
# - name: JS_EXAMPLE_SECRET_REGION
#   value: us-west-2
```

4. #### Retrieve the secret
Retrieve the environment variables and call the function to retrieve secret.
```js
/**
 * We use `onAuthenticateSuccess` here for demonstration purposes, but
 * this could be any Smile CDR callback function that uses the
 * JavaScript Execution Environment.
 */

function onAuthenticateSuccess(theOutcome, theOutcomeFactory, theContext) {

	Log.info('Getting Secret from AWS Secrets Manager...');

    let secretName = Environment.getEnv('JS_EXAMPLE_SECRET_NAME');
    let secretKey = Environment.getEnv('JS_EXAMPLE_SECRET_KEY');

    /**
     * Retrieve secret using default AWS region...
     */
    let secretValue = getSecretsManagerSecretV1(secretName,secretKey)

    /**
     * Or optionally retrieve and use the AWS region:
     *
     * let secretRegion = Environment.getEnv('JS_EXAMPLE_SECRET_REGION');
     * let secretValue = getSecretsManagerSecretV1(secretName,secretKey)
     */

    /**
     * Warning, this will leak your secret to the Smile CDR log files.
     * It is only used here to demonstrate the functionality
     */
    Log.info('Value of secret ' + secretKey + ' is: ' + secretValue) ;

	return theOutcome;
}
```
