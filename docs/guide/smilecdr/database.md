# Database Configuration
To use this chart, you must configure a database. There are two ways to do this:

* Use or provision an external database (or databases) using existing techniques/processes in your
  organisation. Any external database can be referenced in this chart and Smile CDR will be configured
  to use it.
* As a quick-start convenience, support has been included to provision a PostgreSQL cluster locally in
  the Kubernetes cluster using the CrunchyData PostreSQL Operator. When enabling this option, the
  database(s) will be automatically created and Smile CDR will be configured to connect to it/them.

If you do not specify one or the other, the chart will fail to render any output and will return a
descriptive error instead.

> **WARNING - Do not use built-in H2 database**:<br>
Due to the ephemeral and stateless nature of Kubernetes Pods, there is no use case
where it makes sense to provision Smile CDR using the internal H2 database. You are free to configure
your persistence module to do so, but every time the Pod restarts, it will start with an empty
database and will perform a fresh install of Smile CDR. In addition to this, if you were to configure multiple replicas,
each Pod would appear as its own distinct Smile CDR install.

>As such, you should not configure Smile CDR in this fashion and you must instead provision some external database.

## Referencing Externally Provisioned Databases
To reference a database that is external to the cluster, you will need:

* Network connectivity from the K8s cluster to your database.
* A secret containing the connection credentials in a structured Json format.
    * It is common practice to include all connection credentials in DB secrets, this way it becomes simple
    to manage the database without having to reconfigure Smile CDR. e.g. when 'restoring' an RDS instance, the
    DB cluster name will typically change. By keeping these details inside the secret then any such change will be automatically applied without reconfiguring. See
    [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres)
    for info on the schema used by AWS for this purpose. Note that an app restart will be required to pick up the new secret value.
    * The secret can be a Kubernetes `Secret` object that you provision through some external mechanism, or it can be a secret in a
    secure secrets vault. The latter is the preferred option for increased security and the ability to easily
    rotate credentials. At this time, the only supported secrets vault is AWS Secrets Manager, using the Secrets Store CSI Driver.
    See the [Secrets Handling](../index.md) section for more info on this.
    * It's also possible to configure connection details directly without using a secret object. However, any secret material such as passwords MUST use a secret mechanism or alternatively use IAM (See below).
* Authorization can either use a password stored in a secret, or if using certain AWS RDS database types, it can use IAM Authentication.
    * When using IAM Authentication, the IAM Role assigned to the Pod's `ServiceAccount` must have the appropriate IAM policy.
    * Other connection details (e.g. DB URL, Port, database name, username) can either be configured using a Secret object as per above, or they can be specifuid directly in the configuration.

### Database Connection Configuration Schema

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

### Legacy Database Connection Configuration Schema

In Helm Chart version v1.0.0-pre.121 and older, the Database schema was more restrictive:

* It did not allow for different credential mechanisms for each database
* It did not follow the same `secretSpec` schema used elsewhere in the Helm Chart.
#### Using AWS Secret JSON structure
If you are using the above mentioned JSON [structure](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres) (i.e. `engine`, `host`, `username`, `password`, `dbname` and `port`) in your secret, then you should simply configure your secret as per the following yaml fragment. Those default keys will be used to extract the credentials.

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

#### Migrating from legacy to new Database Connection Configuration Schema

To aid in upgrading to the new version of the DB Connection Configuration Schema, Helm Chart version v1.0.0-pre.122 and newer will fail with a descriptive error message.
<!-- In addition to this, it will attempt to convert your provided legacy configuration that can be used to replace the old one in your values file. -->

To convert, you should do the following:

* Move configuration from `database.external.credentials` section to `database.external.defaults.connectionConfigSource` or to `database.external.databases.[databaseIndex].connectionConfigSource`
* Move `secretName` and `secretArn` from `database.external.databases.[databaseIndex]` to `database.external.databases.[databaseIndex].connectionConfigSource`
* Change `database.external.databases.[databaseIndex].module` from a single value to an array of values at `database.external.databases.[databaseIndex].modules`

The above provided example would become:

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




#### Settings Reference

**`databases` Section**

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

## Example External Database Configurations

### Using Secret Store CSI and default Json structure

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

### Using Custom Secret Json structure
If the Json keys in your secret are different than above, they can be overridden by specifying them with the `*Key` attributes to override the defaults.

The below is just an incomplete example to demonstrate how the Json keys can be overridden. You need to ensure that this matches the configuration of your secret and the keys it contains.

> **Note:** `clustermgrSecret` can be any friendly name, it's not important. The Kubernetes `Secret` resource will be named using this value.
#### Using Custom Secret JSON structure
If the JSON keys in your secret are different than above, they can be overridden by specifying them with the `*Key` attributes to override the defaults.

The below are just examples, to show how the JSON keys can be overridden. You need to ensure that this matches the configuration of your secret and the keys it contains.
#### `my-values.yaml`
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

### Using IAM Authentication with Secret for connection details

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

### Using IAM Authentication without Secret for connection details

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
> **NOTE**: You cannot override the passKey value. The password will always come from the
referenced secret unless you are using IAM.

## Using CrunchyData PGO Databases
This chart supports automatic creation of an in-cluster Postgres database using the CrunchyData Postgres Operator (PGO).

In order to use this feature, you will need to ensure that your K8s cluster already has the operator installed
(Operator installation instructions [here](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/)).

After the PGO operator is installed and configured in your Kubernetes cluster, you can enable this feature using the following yaml fragment for your database configuration:
#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
```
This will create a 2 instance HA PostgreSQL cluster, each with 1cpu, 2GiB memory and 10GiB
storage. These defaults can be configured using `database.crunchypgo.config` keys.

Backups are enabled by default as it's a feature of the Operator.

## Configuring Multiple Databases
This chart has support to use multiple databases. It is recommended (and in some cases, required) to configure Smile CDR this way, with
a separate DB for the Cluster Manager, Audit logs, Transaction logs and for any Persistence Modules.

> **Note**If there is only one database configured then it will be used for all modules.

### Module Autoconfiguration of Databases
This Helm Chart will automatically configure any Smile CDR modules that use a database.

If you configure multiple databases, the `module` key specified for each one is used to determine which
Smile CDR module is using it. This key is important as it tells the Helm Chart which module uses this database.

#### Environment Variables
In the examples below, the `clustermgr`, `audit`, `transaction` and `persistence` modules will automatically
have their own set of environment variables configured for DB connections as follows: `CLUSTERMGR_DB_*`, `AUDIT_DB_*`, `TRANSACTION_DB_*` and
`PERSISTENCE_DB_*`

#### Module Configuration
As the modules are configured automatically, you must ***NOT*** manually update your module configurations to point to these environment variable references.

When a given module is configured, any `DB_*` placeholders in the Helm Values files are automatically replaced with the appropriate `<modulename>_DB_*` values.

For example the default Cluster Manager values file has DB connection settings that look like this:

```yaml
db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
db.password: "#{env['DB_PASS']}"
db.username: "#{env['DB_USER']}"
```
The Helm Chart will generate a Smile CDR properties file with automatically updated values to match the environment variabls, like so:

```jproperties
module.clustermgr.config.db.url      = jdbc:postgresql://#{env['CLUSTERMGR_DB_URL']}:#{env['CLUSTERMGR_DB_PORT']}/#{env['CLUSTERMGR_DB_DATABASE']}?sslmode=require
module.clustermgr.config.db.password = #{env['CLUSTERMGR_DB_PASS']}
module.clustermgr.config.db.username = #{env['CLUSTERMGR_DB_USER']}
```

This will happen automatically for any module that references `DB_*` environment variables.

With multiple databases, the examples given above may look like this:

### External Multiple Database Example
#### `my-values.yaml`
```yaml
database:
  external:
    enabled: true
    credentials:
      type: sscsi
      provider: aws
    databases:
    - secretName: smilecdr
      module: clustermgr
    - secretName: smilecdr-audit
      module: audit
    - secretName: smilecdr-txlogs
      module: transaction
    - secretName: smilecdr-pers
      module: persistence
```

### CrunchyData PGO Multiple Database Example
>**Note**The CrunchyData PGO is a little different from the above as it uses the concept of 'users' in the configuration
to configure multiple databases. That is why we are specifying multiple users here:.

#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
    users:
    - name: smilecdr
      module: clustermgr
    - name: smilecdr-audit
      module: audit
    - name: smilecdr-txlogs
      module: transaction
    - name: smilecdr-pers
      module: persistence
```

### CrunchyData Database Name Suffixes
When using CrunchyData PGO for experimenting with different Smile CDR configurations, it is often convenient to experiment with a fresh (empty) database,
or flip back and forth between multiple database configurations.

There are multiple ways this could be done:

* Deprovision/Reprovision the Db cluster - Destructive and time consuming
* Manually drop and recreate databases - Destructive and time consuming. Also requires DB tooling and connectivity.
* Reconfigure the database definitions in the `crunchypgo` section of the values file

These methods have shortcomings that can slow down progress of testing initiatives.

* All of these options can be time consuming and error prone
* Any dropped and recreated databases will naturally lose any data
* Manually reconfiguring, although non-destructive, can get tedious and error-prone when dealing with configurations that have many databases,
especially if you wish to 'flip' back and forth between different database configurations.

As a convenience function, it is possible to quickly alter the database names, either individually or as an entire group.
This can be done by using `dbName` or `dbSuffix`. The default suffix is `-db` and `-` will be prefixed on any provided suffix.

#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
    users:
    # Unaltered DB name will be `clustermgr-db`
    - name: smilecdr
      module: clustermgr

    # Overridden DB name with disabled suffix will be `my-persistence-db-name`
    - name: smilecdr-pers
      module: persistence
      dbName: my-persistence-db-name
      dbSuffix: ""

    # Default DB name with overridden suffix will be `audit-mydbsuffix`
    - name: smilecdr-audit
      module: audit
      dbSuffix: "-mydbsuffix"
```

To reduce needing to specify the db suffix for multiple databases, the default suffix can be changed by setting `defaultDbSuffix` at the root level of the `crunchypgo` configuration as follows:

>**Note**You can still override the suffix for a single DB, as can be seen below with the `audit` and `persistence` modules below.

#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
    defaultDbSuffix: test2
    users:
    # DB name will be `clustermgr-test2`
    - name: smilecdr
      module: clustermgr

    # DB name will be `audit-test1`
    - name: smilecdr-audit
      module: audit
      dbSuffix: test1

    # DB name will be `transaction-test2`
    - name: smilecdr-txlogs
      module: transaction

    # DB name will be `persistence`
    - name: smilecdr-pers
      module: persistence
      dbSuffix: ""
```
