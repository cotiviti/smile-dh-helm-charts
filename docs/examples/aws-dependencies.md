# Configuring AWS Dependencies

This example shows how you would install dependencies in an AWS environment.

We will go over the creation of the following AWS resources in preparation for deploying Smile CDR using the Helm Chart.

* IAM Role using IRSA
* AWS Secrets Manager

>**Note:** These resources are configured in a way that is not obvious to an AWS administrator that has not dealt with IRSA before, which is why we are including them here. For other AWS resources (Such as RDS, S3, Certificates Manager etc) conventional configurations can be used, so we do not cover them in this example at this time.

You will need both of these if you are using the recommended method of storing your container registry secrets - [using Secrets Store CSI Driver](../guide/secrets/index.md#secrets-store-csi-driver)

<!-- * ACM (Certificate Manager) (Coming Soon)
* RDS (Coming Soon)
* S3 (Coming Soon) -->

## Creating IAM Role with IRSA

To set up an IAM Role to be used by the application pods, we use IRSA (IAM Roles for Service Accounts). Detailed information and instructions for IRSA are located [here](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

In this example, we will be creating the role to work with an deployment of Smile CDR in a fictional EKS cluster with the following properties:

* AWS Region `us-east-1`
* Cluster Name `mycluster`
* Namespace `smilecdr`
* Helm Release Name `my-smile`

These are important as they will be referenced in the trust policy.

### IAM Policy
Before starting, you need to determine which AWS services need to be accessed by this role. Typical examples would be:

* AWS Secrets Manager - Used for storing credentials for container repository and database
* RDS - Required if Smile CDR is configured to use IAM authentication for RDS
* S3 - Required if you are including [extra files using the external](./extra-files-external.md) method

You will need to keep these resources in mind when creating your IAM Policy.

>**Note:** When creating IAM Policies, you should keep the principle of least privilege in mind and only allow the minimum required access for the resources needed. Avoid using wildcard entries for `actions` and `resources` where possible.

In this example, we will create a policy that only has access to the container repository secret that we [create below](#create-secret)

Following the AWS CLI instructions from [here](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html) we would do the following:

1. **Create an IAM policy file**

    Create IAM Policy file with the following content:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "secretsmanager:GetSecretValue",
                "Resource": "arn:aws:secretsmanager:us-east-1:<accountid>:secret:demo/dockerpull-??????"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "kms:Encrypt",
                    "kms:Decrypt"
                ],
                "Resource": "arn:aws:kms:*:<accountid>:aws/secretsmanager"
            }
        ]
    }
    ```

    >**Note:** The `??????` is a wildcard that matches the random suffix added to an AWS Secrets Manager Secret. See [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_examples.html#auth-and-access_examples_wildcard) for more info.

2. **Create the IAM Policy**
```sh
aws iam create-policy --policy-name smilecdr-dockersecret-policy --policy-document file://my-policy.json
```

### IAM Role

When creating the IAM role, it needs to be associated with the Kubernetes service account via a trust policy. To do this, we need a few details in advance:

**AWS Account number**
```sh
account_id=$(aws sts get-caller-identity --query "Account" --output text)
```

**EKS cluster's OIDC provider**
```sh
oidc_provider=$(aws eks describe-cluster --name mycluster --region us-east-1 --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
```
**Namespace and ServiceAccount Resource Names**

In the case of this example, we are using the `smilecdr` namespace, with the `my-smile` release name as mentioned above. This will result in a Service Account with the name `my-smile-smilecdr`
```sh
export namespace=smilecdr
export service_account=my-smile-smilecdr
```

1. Create trust policy file

    ```sh
    cat >trust-relationship.json <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
            "$oidc_provider:aud": "sts.amazonaws.com",
            "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
            }
        }
        }
    ]
    }
    EOF
    ```

2. Create the IAM Role
```sh
aws iam create-role --role-name smilecdr-role --assume-role-policy-document file://trust-relationship.json --description "Smile CDR Application Role"
```

3. Attach the IAM Policy to the role
```sh
aws iam attach-role-policy --role-name smilecdr-role --policy-arn=arn:aws:iam::$account_id:policy/smilecdr-dockersecret-policy
```

## Using IAM Role in Helm Values
Configure your values file to use this role for the Service Account like so:
```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account id>:role/smilecdr-role
```

Now, when you deploy Smile CDR, it will use the above IAM role whenever accessing AWS resources.

## Creating AWS Secrets Manager Secrets

Secrets can be a bit of a chicken-and-egg problem.

*If you want to avoid storing secrets in code, by using a secrets vault, how do you do this 'via code'?*

One mechanism is to get the vault software to generate a random secret, or rotate the secret after the initial creation. These are not always viable options, which is certainly the case for storing secrets to access external systems, such as a container registry.

In this example, we will create the `docker pull` secret manually via the AWS CLI. You could just as easily deploy the secret using some other mechanism and then update it with the cli or with the AWS console.

### Create Secret
The value of Kubernetes `imagePullSecrets` needs to be of type `kubernetes.io/dockercfg` or `kubernetes.io/dockerconfigjson`.

This essentially means the secret value is a JSON string representing the Docker `config.json` file. As an AWS Secrets Manager secret consists of a JSON map of secrets and values, we end up with a nested JSON data structure.

The easiest way to pass this to the AWS CLI command is to temporarily store the JSON in a file which can be passed in to the `create-secret` command as a parameter.

1. Create the temporary password JSON file

Update your user & password before running the below.

```sh
cat >dockerconf.json <<EOF
{
  "auths":{
    "docker.smilecdr.com":{
      "auth": "$(echo -n "user:password" | base64)"
    }
  }
}
EOF

cat >tempsecret.json <<EOF
{
  "dockerconfigjson": "$(cat dockerconf.json)"
  }
}
EOF
```

2. Create the Secrets Manager Secret
```sh
aws secretsmanager create-secret \
    --name "demo/dockerpull" \
    --secret-string file://tempsecret.json
```
>**Note:** The name `demo/dockerpull` is just an example. You may use any scheme that you like for secret names. If you have an existing standard, use that.

3. Remove the temporary secret file
```sh
rm tempsecret.json
```

### Update Secret
Use the following to update the secret with a new value if required.

```sh
aws secretsmanager update-secret \
    --secret-id "demo/dockerpull" \
    --secret-string file://tempsecret.json
```

>**Note:** You need to update rather than delete and recreate, as AWS Secrets Manager implements a grace period on secrets deletion.

### Use The Secret
If the IAM Role, IAM Policies and Helm Values were all set up correctly as per the above steps, you will now be able to launch pods using images from the authenticated container repository.
