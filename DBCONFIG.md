There has been some back and forth on how to configure databases for the multiple modules.

Currently:

* Uses the `database` section of the values file.
* Section is used to both configure DB provisioning as well as vconfiguring to use external DB

This seems OK, so we will keep it.

For the external DB configuration:

**Current DB config Schema**

```
database:
  external:
    enabled: true
    credentials:
      type: sscsi
      provider: aws
    databases:
    - secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
      secretName: k8sSecretName
      module: clustermgr
      dbname: cdr-clustermgr
```
This falls short as the `credentials` is global here which means you cannot configure multiple databases to use different credentials.
Also, the credentials is not really reflective of what's inside. It's only really info about the type of credentials - sscsi, k8sSecret etc.

Also, using this schema did not support using IAM for RDS authentication.

**Updated DB config Schema**

The above schema was modified to look like so. This was primarily to add IAM support, but it also enabled having different configurations for different modules.

```
database:
  external:
    enabled: true
    defaults:
      credentials:
        type: sscsi
        provider: aws
    modules:
      clustermgr:
        credentials:
          type: sscsi
          provider: aws
        secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
        secretName: k8sSecretName
        dbname: cdr-clustermgr
```

This structure allowed for different modules to have different DB configurations. At the same time, IAM support was included.
Now you can set `credentials.type` to `iam`, `sscsi` or `k8sSecret`

As it turns out, this does not actually make sense. Some of the material in k8sSecret is still required when ising IAM, so they are not mutually exclusive.

**Requirements Study**

To determine an appropriate schema, we need to look more at the requirements.

* A module may have a DB configured
* It needs the connection details
* Connection details can be provided directly in the yaml, or directly in the values file.
   * Note that passwords cannot be passed directly in the values file.
* When using IAM, some connection details may still be required. (Just not the password!)
* Each DB could in theory be used by multiple modules.
* Each module can only have a single DB connection as far as I am aware.

We also need to categorize the info to keep it in the correct logical location.

* Credentials
* Connection Info
* Auth mechanism

**New work-in-progress Schema**
```
database:
  external:
    enabled: true
    defaults:
      connectionInfo
        source: sscsi
        provider: aws
      auth:
        type: iam/password
    databases:
    - name: clustermgr
      connectionInfo:
        source: sscsi
        provider: aws
        secretArn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"
        secretName: k8sSecretName
      auth:
        type: iam/password
      dbname: cdr-clustermgr
```
