# Connecting to an External Database
This Helm chart supports connecting Smile CDR to any externally provisioned PostgreSQL database, including managed services like Amazon RDS. When using an external database, you must provide connection details and credentials through one of the supported methods described below.

## Requirements

To connect to an external database, ensure the following prerequisites are met:

* Network connectivity from the Kubernetes cluster to the database endpoint.
* Connection details and credentials, ideally provided via a secrets vault.

## Database Authentication Methods
There are multiple authentication mechanisms available, depending on the database vendor being used.

### IAM Authentication (AWS RDS Only)
When using AWS RDS, it is recommended to use IAM authentication to connect to the database if possible.

When using this mechanism, no secrets need to be created or managed. This results in:

* **Improved Security**: No secrets exist, so cannot be leaked from the environment.
* **Improved Operational Efficiency**: No management of secrets required (e.g periodic secret rotation)

### Direct Secrets Manager Authentication (AWS RDS Only)
When using AWS RDS, it is possible to use AWS Secrets Manager secrets directly in the configuration.

While not as secure as the IAM option above, it's a viable alternative if you are unable to configure your RDS database to use IAM authentication.

* **Reduced Security**: Secrets do need to be created, but do not get exposed directly in the Smile CDR pods
* **Reduced Operational Efficiency**: Secrets still need to be managed (Secured and rotated regularly)

### Secret Vault Integration
This Helm Chart supports regular secret vault integration for all external database options, by using the Secrets Store CSI to securely mount secrets from a secret vault into the Smile CDR pods.

This is the recommended solution if you are unable to use IAM authentication or direct AWS Secrets Manager Authentication.

!!! note
    Currently, the only supported secret vault is AWS Secrets Manager.

    Support for other vaults will be added in future versions of the Helm Chart.

### Secret Vault JSON structure
Secrets containing database credentials need to be stored using the JSON structure mentioned [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres).

```json
{
  "engine": "postgres",
  "host": "<instance host name/resolvable DNS name>",
  "username": "<username>",
  "password": "<password> - optional: Not required if using IAM auth",
  "dbname": "<database name>",
  "port": <TCP port number>
}
```

This is the default secret data format used by AWS RDS when it manages secrets. It includes all connection details including `engine`, `host`, `username`, `dbname` and `port` and acts as the single source of truth for connection information for any given database.

This approach simplifies configuration of databases in Smile CDR as you do not need to explicitly configure these details. Instead, a single configuration that points to the AWS Secrets Manager Secret is all that is required.

This is especially helpful in reducing the likelihood of introducing errors the event of switching between RDS instances (i.e. blue-green deployments) or restoring RDS instances (Where the DB cluster name will likely change) as the DB configuration only needs to be updated in a single place.

!!! note
    If IAM authentication is being used, the Secrets Manager secret is not strictly required, as no secret material (i.e. password) needs to be stored. However it is still beneficial to use one to store the remaining DB connection details for the above mentioned reasons.

### Kubernetes Secrets
It is also possible to manually create Secret resources in Kubernetes and reference them, but this is *not recommended* due to the extra maintenance overhead and reduced security posture.

## Configuration

External database connections are configured in the `database.external` section of your values file as follows:

```yaml
database:
  external:
    enabled: true
    defaults:
      connectionConfigSource:
        # sscsi or k8sSecret
        source: sscsi
        provider: aws
        # pwd or iam
      connectionConfig:
        authentication:
         type: pwd
    databases:
    - name: clustermgrdb-iam
      modules:
      - clustermgr
      connectionConfigSource:
        source: none
      connectionConfig:
        authentication:
          type: iam
          provider: aws
        url: clustermgr-db-url
        port: clustermgr-db-port
        dbName: clustermgr-db-name
        user: clustermgr-db-user
```

### Using IAM or Direct Secrets Manager Authentication
#### IAM Prerequisites
Before configuring Smile CDR to use IAM authentication, you need to ensure the following:

* The IAM role for the Smile CDR pod has appropriate permissions to access the RDS database.
* You are using an AWS RDS database, configured to allow IAM authentication using the correct IAM role.
* This should be done for each user/database that you plan to use.

!!! note
    These are not in scope of the Helm Chart documentation, but the Smile CDR Dependencies Terraform module is able to perform these configurations automatically.

#### Direct Secrets Manager Authentication Prerequisites
Before configuring Smile CDR to use direct AWS Secrets Manager authentication, you need to ensure the following:

* You have created an AWS Secrets Manager Secret using the regular JSON secret format.
* The IAM role for the Smile CDR pod has appropriate permissions to access the above AWS Secrets Manager Secret.

#### IAM Configuration
For each database being configured under `database.external.databases`, configure as follows:

```yaml
connectionConfig:
  authentication:
    provider: aws
    type: iam
```

Although no password is required when using IAM authentication, you still need to provide other connection information. This can either be done using AWS Secrets Manager, or you can specify the remaining details manually.

**Connection Details in Secrets Manager**

If using Secrets Manager, and if the secret uses the regular JSON secret format, simply add the AWS Secrets Manager secret ARN under `connectionConfigSource.source`

```yaml
    databases:
    - name: clustermgrdb-iam
      modules:
      - clustermgr
      connectionConfigSource:
        source: secrets-manager-secret-ARN
      connectionConfig:
        authentication:
          type: iam
          provider: aws
```

**Using Manual Connection Details**

If you are not using Secrets Manager as the source of these details, you **must** provide them as follows.

```yaml
    databases:
    - name: clustermgrdb-iam
      modules:
      - clustermgr
      connectionConfigSource:
        source: none
      connectionConfig:
        authentication:
          type: iam
          provider: aws
        url: clustermgr-db-url
        port: clustermgr-db-port
        dbName: clustermgr-db-name
        user: clustermgr-db-user
```

#### Direct Secrets Manager Authentication Configuration
For each database being configured under `database.external.databases`, configure as follows:

```yaml
connectionConfig:
  authentication:
    provider: aws
    type: secretsmanager
connectionConfigSource:
  source: secrets-manager-secret-ARN
```

!!! note "Note on Smile CDR AWS Advanced JDBC Driver"
    As of Smile CDR `2025.05.R01`, the new AWS Advanced JDBC Driver is being used to manage connection configuration when using IAM or AWS Secrets Manager authentication.

    To enable this, the mechanism used to configure Smile CDR has changed. See [here](https://smilecdr.com/docs/v/2025.08.PRE/database_administration/rds_auth.html#aws-advanced-jdbc-driver) for more information on this change.

    This Helm Chart will automatically select the appropriate configuration method depending on the version of Smile CDR being deployed. See [Choosing Smile CDR Versions](../../upgrading/index.md#choosing-smile-cdr-versions) for more info.

### Configuration Reference

**`database.external.databases` Section**

This section contains a list of all external database connection configurations.

| Key | Value | Required | Notes |
|-----|-------|----------|-------|
|`name`|A friendly reference name for this connection.|:material-check:||
|`modules`|List of modules that this connection is used by|:material-close:|If not present, connection may be used by any modules.|
|`connectionConfigSource`|Source of connection credentials (e.g. secrets)|:material-close:|Not required if sufficient defaults are defined|
|`connectionConfig`|Directly configured connection configurations|:material-close:|Not required if sufficient defaults are defined|

**`connectionConfigSource` Section**

This section configures where the database connection settings are pulled from.
Any required configurations must come from the `defaults` section or from the per-connection section. If they are not provided anywhere, the chart will fail with a descriptive error message.

| Key | Value | Required | Notes |
|-----|-------|----------|-------|
|`source`|`sscsi`,`k8sSecret` or `none`|:material-check:|Can only use `none` if using IAM Authentication|
|`provider`|SSCSI Provider, e.g. `aws`|:material-close:|Required if using Secrets Store CSI Driver (sscsi). Only `aws` provider is currently supported.|
|`secretName`|Secret object name|:material-close:|Required if using Kubernetes Secrets (`k8sSecret`) or Secrets Store CSI Driver (`sscsi`).|
|`secretArn`|Secrets Manager ARN|:material-close:|Required if using Secrets Store CSI Driver (`sscsi`).|
|`secretKeyMappings`|Dictionary of key mappings|:material-close:|If you are using key names in your secrets that differ from the defaults, you can provide a custom mapping|

**`secretKeyMappings` Section**

This section lets you configure custom key mappings. If you are not using the above mentioned Json [structure](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres) (i.e. `engine`, `host`, `username`, `password`, `dbname` and `port`) in your secret, they can be overridden by specifying them with the `*Key` attributes to override the defaults

| Key | Value |
|-----|-------|
|`urlKey`|Secret Key Name for URL|
|`portKey`|Secret Key Name for Port|
|`dbNameKey`|Secret Key Name for db name|
|`userKey`|Secret Key Name for username|
|`passKey`|Secret Key Name for password|

**`connectionConfig` Section**

This section is used to directly specify DB connection configurations.

| Key | Value | Required | Notes |
|-----|-------|----------|-------|
|`authentication`|Define authentication mechanism|:material-check:|Defaults to use 'password' authentication. This implies you cannot use `none` as the config source, as you need a password to be provided via a secure mechanism.|
|`authentication.provider`|Define authentication provider|:material-close:|Required when using `iam` authentication. Only `aws` provider is currently supported.|
|`url`|Database hostname|:material-close:|This value acts as an override and will be used even if the credential is provided in a secret object.|
|`port`|Database port|:material-close:|This value acts as an override and will be used even if the credential is provided in a secret object.|
|`dbName`|Database name|:material-close:|This value acts as an override and will be used even if the credential is provided in a secret object.|
|`user`|Database username|:material-close:|This value acts as an override and will be used even if the credential is provided in a secret object.|

#### `defaults` Section

To avoid duplication of configuration settings, it's possible to set defaults for the `connectionConfigSource` and `connectionConfig` sections.


### Legacy Database Configuration Schema
In Helm Chart version v1.0.0-pre.121 and older, the Database schema was more restrictive.

??? info "See More..."

    **v1.0.0-pre.121 Database Configuration Schema**
    The previous Database schema was more restrictive in that:

    * It did not allow for different credential mechanisms for each database.
    * It did not follow the same `secretSpec` schema used elsewhere in the Helm Chart.
    * It did not allow for a single set of credentials to be used in multiple Smile CDR modules.

    **Legacy Schema**
    ```yaml
    database:
      external:
        enabled: true
        credentials:
          type: sscsi
          provider: aws
        databases:
        - secretName: clustermgrSecret
          secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
          module: clustermgr
    ```

    >**Note:** This legacy schema has been deprecated and will be removed from a future version of the Helm Chart.

    **Migrating from legacy to new Database Connection Configuration Schema**

    To aid in upgrading to the new version of the DB Connection Configuration Schema, Helm Chart version v1.0.0-pre.122 and newer will give a warning with a descriptive error message if the old schema is being used.
    <!-- In addition to this, it will attempt to convert your provided legacy configuration that can be used to replace the old one in your values file. -->

    To convert, you should do the following:

    * Move configuration from `database.external.credentials` section to `database.external.defaults.connectionConfigSource` or to `database.external.databases.[databaseIndex].connectionConfigSource`
    * Move `secretName` and `secretArn` from `database.external.databases.[databaseIndex]` to `database.external.databases.[databaseIndex].connectionConfigSource`
    * Change `database.external.databases.[databaseIndex].module` from a single value to an array of values at `database.external.databases.[databaseIndex].modules`

    The above legacy example configuration would then become:

    ```yaml
    database:
      external:
        enabled: true
        defaults:
          connectionConfigSource:
            source: sscsi
            provider: aws
        databases:
        - connectionConfigSource:
            secretName: clustermgrSecret
            secretArn: arn:aws:secretsmanager:us-east-1:012345678901:secret:clustermgrSecret
          modules:
          - clustermgr
    ```

## Configuring Multiple Databases
This chart has support to use multiple databases. It is recommended (and in some cases, required) to configure Smile CDR this way, with a separate DB for the Cluster Manager, Audit logs, Transaction logs and for any Persistence Modules.

> **Note**If there is only one database configured then it will be used for all modules.

## Module Autoconfiguration of Databases
This Helm Chart will automatically configure any Smile CDR modules that use a database.

If you configure multiple databases, the `module` key specified for each one is used to determine which
Smile CDR module is using it. This key is important as it tells the Helm Chart which module uses this database.

### Environment Variables
In the examples below, the `clustermgr`, `audit`, `transaction` and `persistence` modules will automatically
have their own set of environment variables configured for DB connections as follows: `CLUSTERMGR_DB_*`, `AUDIT_DB_*`, `TRANSACTION_DB_*` and
`PERSISTENCE_DB_*`

### Module Configuration
As the modules are configured automatically, you must ***NOT*** manually update your module configurations to point to these environment variable references.

When a given module is configured, any `DB_*` placeholders in the Helm Values files are automatically replaced with the appropriate `<modulename>_DB_*` values.

For example the default Cluster Manager values file has DB connection settings that look like this:

```yaml
db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
db.password: "#{env['DB_PASS']}"
db.username: "#{env['DB_USER']}"
```
The Helm Chart will generate a Smile CDR properties file with automatically updated values to match the environment variables, like so:

```jproperties
module.clustermgr.config.db.url      = jdbc:postgresql://#{env['CLUSTERMGR_DB_URL']}:#{env['CLUSTERMGR_DB_PORT']}/#{env['CLUSTERMGR_DB_DATABASE']}?sslmode=require
module.clustermgr.config.db.password = #{env['CLUSTERMGR_DB_PASS']}
module.clustermgr.config.db.username = #{env['CLUSTERMGR_DB_USER']}
```

This will happen automatically for any module that references `DB_*` environment variables.
