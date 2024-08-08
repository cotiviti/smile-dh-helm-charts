# Injecting Extra Secrets
There are a number of situations where it may be required to securely include extra secrets into the pod. For example, there could be JavaScript callbacks or interceptors that expect secrets to be available in the running environment.

Depending on your exact architecture, there are two main ways that this may be done securely.

## Use `secretSpec` configurations
To simplify configuring extra secrets, the same [`secretSpec`](./configuring-secrets.md#the-secretspec-configuration) object that is used elsewhere in the Helm Chart can be leveraged.

Simply add a `secretSpec` configuration under the `secrets` object in your values file:

The following will result in the `mySecretKeyName` key in the `mySecret` AWS Secrets Manager secret, being exposed as an environment variable as well as being mounted to the filesystem.

```yaml
secrets:
  myExtraSecret:
    name: friendlyname
    # sscsi or k8sSecret
    type: sscsi
    provider: aws
    # Name of K8s Secret resource
    secretName: mySecretName
    secretArn: arn:aws:secretsmanager:us-east-1:123456789101:secret:mySecret
    secretKeyMap:
      mySecretKey:
        secretKeyName: mySecretKeyName
        k8sSecretKeyName: myK8sSecretKeyName
        mountSpec:
          mountPath: /home/smile/smilecdr/classes/mountedSecretFile
        envVarName: MY_ENV_VAR_NAME
```
