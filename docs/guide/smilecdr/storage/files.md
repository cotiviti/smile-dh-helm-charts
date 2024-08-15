# Including Extra Files
It is often required to include extra files into your Smile CDR instance. This could be to provide updated configuration changes (e.g. a modified `logback.xml`), provide `.js` scripts, `.jar` files and other libraries to extend the functionality of Smile CDR.

Rather than having to build a custom Smile CDR container image to include these files, it is possible to include them using this Helm Chart.

## Available Methods
There are two mechanisms available to load files.

* Including files in the Helm deployment
* Pulling files from an external location

Each of these mechanisms has its own advantages.

## Choosing Which Method To Use

### Helm Chart Method
Using the **Helm Chart** method is ideal when:

* The files are text based and under 1MiB in size
    * Config files and small scripts are good examples
    * Not ideal for binary files, even if small
* You do not have many files to add
    * Although there is no limit, your configuration will get very hard to manage if you use too many
    * Between 5 & 10 would be a good limit, but this is just a suggestion
* You don't have a mechanism in place to stage the files somewhere (i.e. Amazon S3)
    * This method provides a simple deployment solution as it has no external dependencies

### External Pull Method
Using the **External Pull** method is ideal when:

* You have binary files or large files
    * Any file over 1MiB requires you use this method
* You have many files
    * This mechanism will copy files recursively without clogging up your configuration
* You are able to stage your files and file updates on Amazon S3
    * Currently only S3 is supported, but other external file sources will be added as required
* You wish to pull files that are publicly hosted (e.g. public `.jar` files)

### Using Both Methods:
Using both methods is possible too:

* If you had a set of `.jar` files and scripts being staged on S3, you could still add files using the
Helm chart method if it makes for a simpler workflow
* Be wary that having it split up like this could make your configuration more confusing (i.e. *"Where was that file copied from again?"*)
* Files copied using the Helm Chart method will take precedence over any files copied from an external source.

## Using the Helm Chart Method

To pass in files using the Helm Chart, there are two things you need to do:
1. Use a Helm commandline option to load the file into the deployment
2. Reference and configure the file in your values file.

### Include File in Helm Deployment
To include a file in the deployment, use the following commandline option:
```bash
helm upgrade -i my-smile-env --devel -f my-values.yaml --set-file mappedFiles.logback\\.xml.data=logback.xml smiledh/smilecdr
```
>**WARNING:** Pay special attention to the escaping required to include the period in the filename.
You need to use `\\.` when running this from a shell. This is just the way this works.

This will encode the file and load it into the provided values under the `mappedFiles.logback.xml.data`
key.

### Include File in Values File
The included file also needs to be referenced from your values file so that the chart knows where to mount the file in the application's Pod:
```yaml
mappedFiles:
  logback.xml:
    path: /home/smile/smilecdr/classes
```
As the result of the above, a `ConfigMap` will be created and mapped into the pod at
`/home/smile/smilecdr/classes/logback.xml` using `Volume` and `VolumeMount` resources. If the
content of the file is changed, then it will be automatically picked up on the next deployment. (See [Automatic Deployment of Config Changes](../updating.md#automatic-deployment-of-config-changes) for more info on this)

## Using the External Pull Method
The external pull method can be used to pull files from Amazon S3 or from public websites that publish resources (e.g. Maven).
### How It Works

#### Shared Volumes
Pod-local shared volumes are used for the `classes` and `customerlib` directories so that the files can be copied there before the main Smile CDR container starts up.

These volumes are only accessible to containers running inside the pods and are deleted when the pod is terminated so they are not accessible outside the pod's lifecycle.
If the underlying Kubernetes node volume uses encrypted storage, then these volumes will also be encrypted.

#### Init Containers
Kubernetes init containers are then used to pull files from S3, or some other location.

It uses multiple Kubernetes [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to synchronize and pull files to these shared volumes during pod startup.

This feature has been implemented to support Amazon S3 and curl. Other mechanisms may be introduced in a future version of this chart.

The init containers are auto-configured based on the provided `copyFiles` settings. They function as follows:

**`init-sync-classes`**

* This container copies the default files from the classes directory from the Smile CDR base image to a `classes` shared volume that is local to the pod.
* The `init-pull-classes` container will overwrite any of these files with the same names.
* This is a required step if you wish to retain the default files. As such, it's enabled by default
* If you require a 'clean' `classes` directory, this step can be disabled using `copyFiles.classes.disableSyncDefaults: true`.
    * If disabled, you will need to provide all `classes` files that are required for Smile CDR to start up (With the exception of the config properties file which is generated by this Helm Chart).

**`init-sync-customerlib`**

* This container copies the default files from the customerlib directory from the Smile CDR base image to a `customerlib` shared volume that is local to the pod.
* When using the default Smile CDR image, no files will be copied as the directory is empty.
* If using a customised image with files preloaded into the `customerlib` directory, this step is necessary to prevent those files being clobbered. As such, it's enabled by default.
* If you require a 'clean' `customerlib` directory, this step can be disabled using `copyFiles.classes.disableSyncDefaults: true`.

**`init-pull-classes-*`**

* These containers copy files from the specified location to the ***classes*** shared volume
* Currently they support pulling files from Amazon S3 or downloading files from public websites using `curl`.
* Any files copied will be available to Smile CDR when it starts up

**`init-pull-customerlib-*`**

* This container copies files from the specified location to the ***customerlib*** shared volume
* Currently they support pulling files from Amazon S3 or downloading files from public websites using `curl`.
* Any files copied will be available to Smile CDR when it starts up

### S3 Prerequisites
To pass in files from an Amazon S3 bucket, you need the following prerequisites in place:

* An S3 bucket with:
    * A folder containing your `classes` files
    * A folder containing your `customerlib` files
    * Ideally, these should be in a higher level folder to control versioning
        * e.g. `v1`, `v2` or a `UID`
    * Bucket should not be publicly accessible
        * It will work with public buckets too, but this is a bad security practice
    * Bucket should use encryption
        * Again, it will work without, but it's good security practice to encrypt everything by default
    * The mechanism to copy the files into this bucket is out of the scope of this Helm Chart
* Service Account must be enabled and configured to use IRSA. See [here](../../serviceaccount.md) for more info on this
* The IAM Role used for the Service Account must have read access to the S3 bucket

??? note "Required IAM policy actions for S3 copyFile configurations"


    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ListObjectsInBucket",
                "Effect": "Allow",
                "Action": ["s3:ListBucket"],
                "Resource": ["arn:aws:s3:::bucket-name"]
            },
            {
                "Sid": "GetObjectActions",
                "Effect": "Allow",
                "Action": ["s3:GetObject"], ## or s3:GetObjectVersion
                "Resource": ["arn:aws:s3:::bucket-name/*"]
            }
        ]
    }
    ```

### A Note On File Versioning
Though not required, it is recommended to include some versioning structure in your S3 bucket.

While already running pods cannot be affected by this (As they have already copied their files), any new pods that start up (e.g in scaling or reconciliation events) may be adversely affected if files have been unexpectedly changed or deleted.

By including a new version whenever a given set of files is updated, previous deployments of the application will remain unaffected. This is also beneficial during rollbacks as the previous set of files will remain.

This does introduce challenges of file duplication and managing multiple old versions. As the number of files included is typically low, this should not be of huge concern.

### Configure Helm Values File

To enable this feature, add the following snipped to your values file. Replace the bucket name and path to match your environment.

```yaml
copyFiles:
  classes:
    sources:
    # Copies files recursively from S3 to the classes directory
    - type: s3
      # disableSyncDefaults: true <- Optional. Use with caution! (See above)
      bucket: s3-bucket-name
      path: /path-to/classes
      # Example versioned locations.
      # path: /v1/classes
      # path: /v1.1/classes
      # path: /v2/classes
      # path: /<sha256-of-file-content>/classes <- You could generate a sha256 hash of the entire file contents.
      # path: /<UID>/classes <- You could generate a unique UID for each new version
  customerlib:
    sources:
    # Copies files recursively from S3 to the customerlib directory
    - type: s3
      bucket: s3-bucket-name
      path: /path-to/customerlib-src
    # Downloads a single file using curl to the customerlib directory (In this case, customerlib/elastic-apm/elastic-apm-agent-1.13.0.jar)
    - type: curl
      fileName: elastic-apm/elastic-apm-agent-1.13.0.jar
      url: https://repo.maven.apache.org/maven2/co/elastic/apm/elastic-apm-agent/1.13.0/elastic-apm-agent-1.13.0.jar
```
>**Note:** The Service Account configurations have been left out for clarity. Please refer to the [Service Account guide](../../serviceaccount.md) for instructions on enabling IRSA and IAM roles.
