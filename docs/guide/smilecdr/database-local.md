# Using A Cluster Local Database
This chart supports automatic creation of an in-cluster Postgres database using the CrunchyData Postgres Operator (PGO).

## Requirements
In order to use this feature, you will need to ensure that your K8s cluster already has the operator installed
(Operator installation instructions [here](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/)).

## Basic Configuration
After the PGO operator is installed and configured in your Kubernetes cluster, you can enable this feature using the following yaml fragment for your database configuration:

**`my-values.yaml`**
```yaml
database:
  crunchypgo:
    enabled: true
    internal: true
```

By default, this will create a 2 instance HA PostgreSQL cluster, each with 1cpu, 2GiB memory and 10GiB
storage.

## Advanced Configuration
When enabling crunchypgo using the above example, the database is configured using configuration provided in the default values file as follows:

**`default-values.yaml`**
```yaml
database:
  crunchypgo:
    config:
      # -- PostgreSQL version to use
      postgresVersion: 14
      # -- Number of Postgres instances to run (For HA)
      instanceReplicas: 2
      # -- PostgrSQL cpu allocation
      instanceCPU: 1
      # -- PostgrSQL memory allocation
      instanceMemory: 2Gi
      # -- PostgrSQL storage allocation
      instanceSize: 10Gi
      # -- PostgrSQL backups storage allocation
      backupsSize: 10Gi
      # If you need faster disk for the PostgreSQL cluster, you can specify a higher performance
      # `storageClass` in your cluster and reference it here. e.g.
      #storageClass: gp3-fast
    users:
      # - PostgreSQL username
    - name: smilecdr
      # -- Smile CDR module that will use this user/database
      module: clustermgr
    - name: audit
      module: audit
    - name: transaction
      module: transaction
    - name: persistence
      module: persistence
```

###`database.crunchypgo.config`
The following settings can be updated, allowing you to tune the database size and performance.

* instanceReplicas
* instanceCPU
* instanceMemory
* instanceSize
* backupsSize

#### Backups
Backups are enabled by default as it's a feature of the Cruncht PGO Operator.

When using the default backup mechanism, extra pods will be created to contain the backup repository.

This backup behaviour can be altered by passing in a custom configuration under the `pgBackRestConfig` as follows:

**`default-values.yaml`**
```yaml
database:
  crunchypgo:
    config:
      pgBackRestConfig:
        configuration:
          ...
        repos:
          ...
```

Refer to the [Crunchy PGO Backup Configuration](https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/backups-disaster-recovery/backups) for more information on configuring backups.


### `database.crunchypgo.users`
The `database.crunchypgo.users` section is used to configure users, databases and how they map to Smile CDR modules that require database connections.

As a best security practice, each module in a default install of Smile CDR will have its own database and associated user. As such, the following users are created.

| User Name | Database Name | Module |
| --------- | ------------- | ------ |
| smilecdr  | clustermgr-db    | clustermgr |
| audit     | audit-db         | audit |
| transaction | transaction-db | transaction |
| persistence | persistence-db | persistence |


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
