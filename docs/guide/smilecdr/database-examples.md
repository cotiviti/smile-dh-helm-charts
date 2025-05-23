# Example Database Configurations

## RDS Database Using IAM Authentication

### Using Secret for connection details

This example shows how to use IAM authentication for multiple RDS databases using IAM authentication.

Non-sensitive details such as database endpoints are still stored in AWS Secrets Manager as a single source of truth.

!!! note
    The `defaults` section is used here to reduce repetition of `connectionConfig` and parts of `connectionConfigSource` for each database.

```yaml
database:
  external:
    enabled: true
    defaults:
      connectionConfigSource:
        source: sscsi
        provider: aws
      connectionConfig:
        authentication:
          type: iam
          provider: aws
    databases:
    - name: clustermgrSecret
      modules:
      - clustermgr
      connectionConfigSource:
        secretName: clustermgrSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
    - name: persistenceSecret
      modules:
      - persistence
      connectionConfigSource:
        secretName: persistenceSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:persistenceSecret
    - name: auditSecret
      modules:
      - audit
      connectionConfigSource:
        secretName: auditSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:auditSecret
    - name: transactionSecret
      modules:
      - transaction
      connectionConfigSource:
        secretName: transactionSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:transactionSecret
```

### Directly Configured Connection Details

This example shows how to use IAM authentication for multiple RDS databases using IAM authentication.

All databases reside on the same RDS instance - `shared-db-url` - but still have different users and databases.

Rather than using AWS Secrets Manager for the remaining details, they are added here directly.

!!! note
    The `defaults` section is used here to reduce repetition of `connectionConfig` and parts of `connectionConfigSource` for each database.

```yaml
database:
  external:
    enabled: true
    defaults:
      connectionConfigSource:
        source: none
      connectionConfig:
        authentication:
          type: iam
          provider: aws
        url: shared-db-url
        port: shared-db-port
    databases:
    - name: clustermgrSecret
      modules:
      - clustermgr
      connectionConfig:
        dbName: clustermgr-db-name
        user: clustermgr-db-user
    - name: persistenceSecret
      modules:
      - persistence
      connectionConfig:
        dbName: persistence-db-name
        user: persistence-db-user
    - name: auditSecret
      modules:
      - audit
      connectionConfig:
        dbName: audit-db-name
        user: audit-db-user
    - name: transactionSecret
      modules:
      - transaction
      connectionConfig:
        dbName: transaction-db-name
        user: transaction-db-user
```

## Generic Database Using AWS Secrets Manager secret vault

The following examples show how to use AWS Secrets Manager secrets using the Secret Store CSI

### Using the default JSON secret structure
If using the default [JSON secret structure](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres):

!!! note
    This is NOT the same as using AWS Secrets Manager for Direct Secrets Manager authentication as per the above examples.

    In those cases, Smile CDR was configured to directly use the AWS Secrets Manager secret.

    In this example, the Helm Chart configures the Secret Store CSI to automatically pull the secret from the vault and mount it into the environment of the Smile CDR pod.

```yaml
database:
  external:
    enabled: true
    defaults:
      connectionConfigSource:
        source: sscsi
        provider: aws
      connectionConfig:
        authentication:
          type: pwd
    databases:
    - name: clustermgr
      modules:
      - clustermgr
      connectionConfigSource:
        secretName: clustermgrSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
    - name: persistence
      modules:
      - persistence
      connectionConfigSource:
        secretName: persistenceSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:persistenceSecret
    - name: audit
      modules:
      - audit
      connectionConfigSource:
        secretName: auditSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:auditSecret
    - name: transaction
      modules:
      - transaction
      connectionConfigSource:
        secretName: transactionSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:transactionSecret
```

### Using Custom Secret Json structure
If the Json keys in your secret are different than above, they can be overridden by specifying them with the `*Key` attributes to override the defaults.

This example demonstrates how the Json keys can be overridden. You need to ensure that the overrides match the configuration of your secret and the keys it contains.

!!! note
    You do NOT need to do this if you are using the default JSON structure for secrets, as described [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres):

```yaml
database:
  external:
    enabled: true
    defaults:
      connectionConfigSource:
        source: sscsi
        provider: aws
        secretKeyMappings:
          urlKey: url-key-name
          portKey: port-key-name
          dbnameKey: dbname-key-name
          userKey: user-key-name
          passKey: password-key-name
      connectionConfig:
        authentication:
         type: pwd
    databases:
    - name: clustermgrSecret
      modules:
      - clustermgr
      connectionConfigSource:
        secretName: clustermgrSecret
        secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
```

### Provide connection details directly
If a required field is not included in the secret, you can specify it in a database connection section like so.

```yaml
databases:
  - name: clustermgrSecret
    modules:
    - clustermgr
    connectionConfigSource:
      secretName: clustermgrSecret
      secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
    connectionConfig:
      url: db-url # this is the actual url/hostname
      port: 5432
      dbname: dbname
      user: username
```
!!! note
    You cannot override the passKey value. The password will always come from the referenced secret unless you are using IAM.
