# Configuring Smile CDR License

Some components of Smile CDR require an additional license in order for them to function. In order to enable your license in a secure fashion, please follow this guide.

## Prerequisites

The recommended way to configure your Smile CDR license is by importing it from a secure secrets vault. Currently this chart only supports AWS Secrets Manager using the Secrets Store CSI Driver. For more information on these pre-requisites and how secrets are handled in this chart, please refer to the [Secrets Handling](../secrets.md) section of this guide.

## Configure using Secrets Store CSI

### AWS Secrets Manager

The Smile CDR License is a regular JWT token. When storing it in an AWS Secrets Manager Secret, store it under the `jwt` key in the JSON object.

### Values File

Add a snippet in your values file like so

```yaml
license:
  type: sscsi
  provider: aws
  secretArn: arn:aws:secretsmanager:us-east-1:111111111111:secret:my-smile-license
```

## Alternative method

If you do not wish to use the above method, you can also include your license file using the existing method for including files as described in the [Including Extra Files](./files.md) section of this guide.

If you use this method, you will also need to update your [module configuration](./modules.md) so that `license.config.jwt_file` points to the correct file.

> **WARNING:** Be aware that your license should be considered sensitive material. If you do use this method, your license may show up in your infrastructure logs that are used to provision this Helm Chart.
