# Configuring Secrets

## The `secretSpec` configuration

Secrets can be used in various areas within this Helm Chart. To simplify configuring secrets,
they all make use of a `secretSpec` object that is used consistently in multiple locations.

The `secretSpec` schema looks like this:
``` yaml
name: friendlyname
# sscsi or k8sSecret
type: sscsi
# Provider required if type = sscsi
provider: aws
# Name of K8s Secret resource (This will be lower-cased)
secretName: mySecretName
# Required if type = sscsi and provider = aws
secretArn: arn:aws:secretsmanager:us-east-1:123456789010:secret:secretname

# Secret projection.
# To expose the secret into the environment, you need to configure each secret entry accordinly
# by usint the `secretKeyMap`
# For some configurations (e.g. external DB configurations) this is not required as the secret
# will be automatically mounted in the appropriate fashion.
secretKeyMap:
  # The object name here is unimportant
  mySecretKey:
    # The key name of the secret in the Secret vault, if using sscsi
    secretKeyName: mySecretKeyName
    # The key name of the secret in the kubernetes secret object
    k8sSecretKeyName: myK8sSecretKeyName
    # If specified, will mount secret on the filesystem
    mountSpec:
      mountPath: /home/smile/smilecdr/classes/mountedSecretFile
    # If specified, will mount secret as an environment variable
    envVarName: MY_ENV_VAR_NAME

```

## Where to configure secrets
For information on how this `SecretSpec` is used elsewhere in the Helm Chart, refer to the following sections.

* [Image Repository Credentials](../helm-repo.md#configuring-repo-credentials-using-secrets-store-csi-driver)
* [Database Credentials](../smilecdr/database-overview.md)
* [Smile CDR License](../smilecdr/modules/license.md)
* [Generic Secrets](./extra-secrets.md)

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
Set some appropriate environment variables using the [extraEnvVars](../smilecdr/envvars.md#passing-extra-environment-variables) Helm Chart feature.
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
