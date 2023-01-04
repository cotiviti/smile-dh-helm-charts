# Database Configuration
To use this chart, you must configure a database. There are two ways to do this:

* Use or provision an external database (or databases) using existing techniques/processes in your
  organisation. Any external database can be referenced in this chart and Smile CDR will be configured
  to use it.
* As a quick-start convenience, support has been included to provision a PostgreSQL cluster locally in
  the Kubernetes cluster using the CrunchyData PostreSQL Operator. When enabling this option, the
  database(s) will be automatically created and Smile CDR will be configured to connect to it.

If you do not specify one or the other, the chart will fail to render any output and will return a
descriptive error instead

> **WARNING - Do not use built-in H2 database**:<br>
Due to the ephemeral and stateless nature of Kubernetes Pods, there is no use case
where it makes sense to provision Smile CDR using the internal H2 database. You are free to configure
your persistence module to do so, but every time the Pod restarts, it will start with an empty
database and will perform a fresh install of Smile CDR. In addition to this, if you were to configure multiple replicas,
each Pod would appear as its own distinct Smile CDR install.
As such, you should not configure Smile CDR
in this fashion and you must instead provision some external database.

## Referencing Externally Provisioned Databases
To reference a database that is external to the cluster, you will need:

* Network connectivity from the K8s cluster to your database.
* A secret containing the connection credentials in a structured Json format.
  * It is common practice to include all connection credentials in DB secrets, this way it becomes simple
  to manage the database without having to reconfigure Smile CDR. e.g. when 'restoring' an RDS instance, the
  DB cluster name will typically change. If this is kept inside the secret (As it is with RDS when using AWS
  Secrets Manager) then any such change will be automatically applied. See
  [here](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres)
  for info on the schema used by AWS for this purpose.
  * The secret can be a plain Kubernetes secret that you provision externally, or it can be a secret in a
  secure secrets vault. The latter is the preferred option for increased security and the ability to easily
  rotate credentials. At this time, only AWS Secrets Manager is supported via the Secrets Store CSI Driver.
  See the [Secrets Handling](../guide/secrets) section for more info on this.

If using AWS Secrets Manager, set the `credentials.type` to `sscsi` and `credentials.provider` to `aws`. If you have created a `Secret` object
in Kubernetes, set it to `externalsecret`.

### Example Secret Configuration
Assuming you are using AWS Secrets Manager, and you have the `url`, `port`, `user` and `password` keys
included in the secret, you should configure your secret as per the following yaml fragment.

If the included fields are different in the provided secret, they can be
specified with the `*Key` values to override the below defaults.

The below are just examples, to show how the fields can be specified in different ways. You need to
ensure that this matches the configuration of your secret and the fields it contains.
#### `my-values.yaml`
```yaml
database:
  external:
    enabled: true
    credentialsSource: sscsi-aws (or k8s)
    databases:
    - secretName: smilecdr
      module: clustermgr
      urlKey: url # this is the key name that holds the url/hostname in the secret
      portKey: port
      dbnameKey: dbname
      userKey: user
      passKey: password
```

If a required field is not included in the secret, you can specify it in your values file like so.

#### `my-values.yaml`
```yaml
- secretName: smilecdr
  module: clustermgr
  url: db-url # this is the actual url/hostname
  port: 5432
  dbname: dbname
  user: username
  passKey: password
```
> **NOTE**: You cannot override the passKey value. The password will always come from the
referenced secret.

## Using CrunchyData PGO Databases
In order to use this feature, you will need to ensure that your K8s cluster has the CrunchyData PGO
already installed (Instructions [here](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/)).
Simply enable this feature using the following yaml fragment for your database configuration:
#### `my-values.yaml`
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
```
This will create a 2 instance HA PostgreSQL cluster, each with 1cpu, 2GiB memory and 10GiB
storage. These defaults can be configured using `database.crunchypgo.config` keys. Backups are enabled
by default as it's a feature of the Operator.

## Configuring Multiple Databases
This chart has support to use multiple databases. It is recommended to configure Smile CDR this way, with
a separate DB for the Cluster Manager and for any Persistence Modules.

The `module` key is important here as it tells the Helm Chart which module uses this database.
If there is only one database then it will be used for all modules.

If you provide multiple databases, the `module` key specified in each one is used to determine which
Smile CDR module it is used by.

With multiple databases, the above examples may look like this:

> **Note** The CrunchyData PGO is a little different in that it uses the concept of 'users' in the configuration
to configure multiple databases. That is why we are specifying multiple users below in the **CrunchyData PGO** example.

#### `my-values.yaml` (External Database)
```yaml
database:
  external:
    enabled: true
    credentialsSource: sscsi-aws (or k8s)
    databases:
    - secretName: smilecdr
      module: clustermgr
    - secretName: smilecdr-pers
      module: persistence
```
#### `my-values.yaml` (CrunchyData PGO)
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
    users:
    - name: smilecdr
      module: clustermgr
    - name: persistence
      module: persistence
```
In both of the above examples, the `clustermgr` and `persistence` modules will both automatically
have their own set of environment variables for DB connections as follows: `CLUSTERMGR_DB_*` and
`PERSISTENCE_DB_*`

> **NOTE**: You do NOT need to update these environment variable references in your module
configurations. When the `clustermgr` module definition references `DB_URL`, this will be
automatically mutated to `CLUSTERMGR_DB_URL`. This will happen automatically for any module that
references `DB_*` environment variables.
