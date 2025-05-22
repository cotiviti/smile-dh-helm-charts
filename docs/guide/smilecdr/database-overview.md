# Database Configuration
When deploying Smile CDR using this Helm Chart, **you must configure a database**. If no database settings are provided, `helm install` will fail with an error prompting you to supply the required database configuration.

You have two options for setting up a database:

## Use an external database
You can reference an existing database (or provision a new one) using your organization’s standard tools and processes. The Helm chart allows you to configure Smile CDR to connect to any compatible external database.

See the section on [Connecting to an External Database](./database-external.md) for details on how to do this.
## Provision a local PostgreSQL cluster (for testing or development)
For convenience, this chart supports deploying a PostgreSQL cluster within your Kubernetes environment using the [CrunchyData PostgreSQL Operator](https://access.crunchydata.com/documentation/postgres-operator/latest). If enabled, the necessary databases will be created automatically, and Smile CDR will be configured to use them.

See the section on [Using A Cluster Local Database](./database-local.md) for details on how to do this.

> **NOTE - Built-in H2 database is NOT supported**:<br>
Because Kubernetes Pods are ephemeral and stateless, using the internal H2 database to provision Smile CDR is not recommended. While it is technically possible to manually configure the persistence module to use H2, the database will be wiped each time the Pod restarts, resulting in a fresh Smile CDR installation. Furthermore, if multiple replicas are deployed, each Pod will behave as a separate and independent Smile CDR instance.

## Database Configuration Examples
Refer to the [Example Database Configurations](./database-external.md) section for some common database configuration scenarios.
