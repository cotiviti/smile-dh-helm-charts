# Using The Smile CLI Tool (`smileutil`)

Many operational tasks within Smile CDR can be performed using the `smileutil` tool that is included when installing using this Helm Chart. Please refer to the [`smileutil` documentation](https://smilecdr.com/docs/smileutil/introduction.html) for more information on what functions it supports.

In a local or VM installation, it is a common practice to run this command directly inside a running instance of Smile CDR.

The Smile CDR helm chart currently has limited support for using the Smile CLI as this is an incubating feature set.

## Using Smile CLI in Kubernetes
There are 2 ways that such operational tasks could be performed on a Pod in Kubernetes.

**Exec into Pod**

The simple way to perfom ad-hoc operational tasks is to directly `exec` into the pod using the `kubectl` tool.

When following best security practices, it is not advisable to allow administrators to directly connect to running Pods to perform operational tasks, as doing so may expose a number of security requirements and concerns:

* User must have `kubectl` tooling on their workstation, along with any required credentials for the cloud account and Kubernetes cluster.
* User must have `exec` RBAC permissions in the cluster
* User may be able to view secret material mounted in the running environment
* User may be able to interrupt the running applicaton
* No way to control which `smileutil` commands can be run
* High chance of error when typing commands by hand.
* Low repeatability and re-use of commands and parameters

Currently this is the only mechanism available for running the `smileutil` command when installing using the Smile CDR Helm Chart

**Use `smileutil` Job***

Use a Kubernetes `Job` that performs the `smileutil` command for you in a codified and repeatable manner.

By using a Kubernetes Job, the options passed to `smileutil` can be codified resulting in low manual effort and high repeatability.

>**Note:** Currently, the Smile CDR Helm Chart does not support this functionality. Until this feature is implemented, the **exec into pod** method must be used.

### Preparing Pod and Running `smileutil`

Depending on the particular Smile CLI command you plan to run, you may need to adjust the available resources in your Pod.

#### Prepare Pod resources

**Memory**

When running `smileutil`, it will run its own JVM, with its own memory heap. It may be required to increase the amount of unallocated memory in the Pod if there is not enough. This can be done in multiple ways:

* Increase the Pod [resouce limits](../resources.md) and reduce the `memoryFactor` in the [JVM Heap Auto-Sizing](../resources.md#jvm-heap-auto-sizing).
* Specify a Pod memory limit that is larger than the Pod memory request. The difference between these two values signifies the amount of unallocated memory available to other commands like `smileutil`

**Ephemeral Volumes**

In some cases, the `smileutil` command may need to write temporary file. Alternatively you may need to upload files to the pod in order to run your command. In either of these scenarios, you may need to adjust the size limit of some of the ephemeral volumes, such as `/home/smile/smilecdr/tmp` or `/home/smile/smilecdr/customerlib`.

Refer to the [volume configuration](../storage/volumeConfig.md) and [adding files](../storage/files.md) sections for information on how to do this.

#### Exec into pod

Once your Pod is prepared, you can `exec` into your running pod using the `kubectl` command:

```
kubectl exec -ti <podname> -n <namespacename> bash
```

## Supported Smile CLI Tool Commands

The following `smileutil` commands are currently supported.

### `upload-terminology`

There are two ways to run the upload terminology command.

#### Run from external location
When running this command from an external location, the `smileutil` utility will upload the zip file to the Smile CDR Pod, which will keep a copy of the zip file in memory before unzipping it to the temp dir and processing the records.

For this to work, the pod must be configured as follows:
* JVM heap size must be sufficiently sized. This process requires a lot of memory when dealing with very large zip files. For example, a 600MB zip file will require about 4GB more heap size than normal.
* Temp directory must be large enough to hold the uncompressed data. For example, a typical 600MB terminology zip file may unzip to ~4GB. The temp directory should be set to at least 4GB

Run the following command from your external location:
```
./smileutil upload-terminology -d /path/to/terminology.zip -s 1GB -v r4 -b user:password -t "https://myEnvironment.example.com/fhir_request/" -u "http://snomed.info/sct"
```
>**Note:** It is important to specify the `-s` option to be a value larger than the size of the zip file you are uploading. This forces the command to run in 'remote' mode where it copies the file to the Smile CDR server before unzipping and processing.

#### Run from within a Smile CDR Pod
To reduce resource usage, this command can be run from inside the Smile CDR pod. In this case, you will need to somehow copy the file into the Pod. This can be done either manually using `kubectl cp` or using the [add files](../storage/files.md) functionality to copy the file from S3 to the `customerlib` or `classes` directory. The `smileutil upload-terminology` command will then copy the file to the temp directory and the Smile CDR application will reference the file locally and unzip the file, also to the temp directory.

For this to work, the pod must be configured as follows:
* JVM heap size may need to be increased a little. There is still some overhead required in the Smile CDR JVM, as well as the Smile CLI JVM. A 600MB zip file seems to require ~2GB extra on both.
* Temp directory must be large enough to hold a copy of the zip file as well as all of the uncompressed data. For example, a typical 600MB terminology zip file may unzip to ~4GB. The temp directory should be set to at least 4GB
* The `customerlib` or `classes` directory used to upload the file will need to be large enough to hold the zip file.

Review the Helm Values [example snippet](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/main/examples/helm/values-snippets/smileutil-upload-terminology.yaml) to prepare your environment as described above.

Use `kubectl` to `exec` into your running pod:
```
kubectl exec -ti <podname> -n <namespacename> bash
```

Run the following command from inside the pod:
```
JAVA_OPTS=-Xmx2g /home/smile/smilecdr/bin/smileutil upload-terminology -d /home/smile/smilecdr/customerlib/terminologyfile.zip -v r4 -b user:password -t "http://localhost:8000/fhir_request/" -u "http://snomed.info/sct"
```
>**Note 1:** This assumes a default Smile CDR install with the FHIR endpoint running on port 8000
>**Note 2:** It is important to remove the `-s` option or set it to be a value LOWER than the size of the zip file you are uploading. This forces the command to run in 'local' mode where it copies the file to the temp directory and instructs the Smile CDR server to reference the local file before unzipping and processing.
