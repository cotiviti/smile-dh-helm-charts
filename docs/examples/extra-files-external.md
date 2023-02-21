# Adding Files Configuration

This example demonstrates passing in extra files to the deployment from external sources.

It is based on the [minimal](minimal.md) example.

This will configure Smile CDR as follows:

* Default Smile CDR module configuraton
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via Secret Store CSI Driver using AWS Secrets Manager
* Postgres DB automatically created
* Custom `logback.xml` file will be included in the `classes` directory in Smile CDR, using Amazon S3
* Elastic APM `.jar` file will be included in the `customerlib` directory in Smile CDR, using curl

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* CrunchyData Operator must be installed
* Image repository credentials stored in AWS Secrets Manager
* Amazon S3 bucket with a customized `logback.xml` file copied to a `classes` folder
* AWS IAM Role configured to access:
    * AWS Secrets Manager
    * Amazon S3 bucket

## Values File
```yaml
specs:
  hostname: smilecdr.mycompany.com

image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: sscsi
    provider: aws
    secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

database:
  crunchypgo:
    enabled: true
    internal: true

copyFiles:
  classes:
    sources:
    # Copies files recursively from S3 to the classes directory
    - type: s3
      bucket: s3-bucket-name
      # The below S3 bucket prefix must contain the custom logback.xml
      # file, as well as any other needed files.
      path: /path-to/classes
  customerlib:
    sources:
    # Downloads a single file using curl to the customerlib directory
    # (In this case, customerlib/elastic-apm/elastic-apm-agent-1.13.0.jar)
    - type: curl
      fileName: elastic-apm/elastic-apm-agent-1.13.0.jar
      url: https://repo.maven.apache.org/maven2/co/elastic/apm/elastic-apm-agent/1.13.0/elastic-apm-agent-1.13.0.jar
```
