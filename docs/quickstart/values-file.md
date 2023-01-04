# Create a Helm values file for your environment
To use the Smile CDR helm Chart, you will need to create a values file with some mandatory fields provided.

## A note on creating values files
Do not copy the default `values.yaml` file from the Helm Chart, start from a fresh empty file
instead.

See the section on [Values Files Management](../../guide/values-files-management/) for more info on this.
<!--The default values file is very long and may contain values that are not relevant or
appropriate for your specific deployment. By creating your own values file, you can ensure
that only the values that you need to override are included.

The default values file may be updated in future releases of the chart, which could potentially
break your deployment if you are relying on an older version of the default values.
By creating your own values file, you can ensure that your deployment is not affected by such
changes to the default values.

Creating your own values file from scratch gives you greater control and flexibility over your
Helm chart deployment, and helps to ensure that your deployment is secure and stable. -->

## Example Values File
The following example will work in any Kubernetes environment that has the following components installed.

* Nginx Ingress
* CrunchyData PGO
* A suitable Persistent Volume storage provider (For the database).

You will need to update the values specific to your environment and include credentials for
a container repository that contains the Smile CDR Docker images.

> **WARNING**: The following method of providing Docker credentials in the values file is insecure
and only shown in this quick-start demonstration to show the chart in action.
You should instead use an alternative such as an external secret vault.
At the very least, provision the Kubernetes Secret object in a separate process that does not
store the secret anywhere in code.

**`my-values.yaml` file**
```yaml
specs:
  hostname: smilecdr.mycompany.com
image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: values
    values:
    - registry: docker.smilecdr.com
      username: <DOCKER_USERNAME>
      password: <DOCKER_PASSWORD>
database:
  crunchypgo:
    enabled: true
    internal: true
```
