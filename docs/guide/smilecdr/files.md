# Mapping files
It is often required to add extra files into your Smile CDR instance. This could simply be to
provide updated configuration changes (e.g. `logback.xml`) or to provide scripts to extend the
functionality of Smile CDR.

Rather than having to build a new Smile CDR container image with these files included, it is
possible to include them using this Helm Chart.
> **NOTE**: At this time, due to the way Kubernetes works, it is only possible to pass small (<1MiB) files into Smile CDR using This
method, so it is only suitable for configuration files and scripts. Larger files, such as `.jar`
files, other binaries or large datasets are not supported using this method. There will be a solution for larger files in a future version of this chart.

To pass in files, there are two things you need to do:
1. Use a Helm commandline option to load the file into the deployment
2. Reference and configure the file in your values file.

## Include File in Helm Deployment
To include a file in the deployment, use the following commandline option:
```bash
helm upgrade -i my-smile-env --devel -f my-values.yaml --set-file mappedFiles.logback\\.xml.data=logback.xml smiledh/smilecdr
```
> **WARNING**: Pay special attention to the escaping required to include the period in the filename.
You need to use `\\.` when running this from a shell. This is just the way this works.

This will encode the file and load it into the provided values under the `mappedFiles.logback.xml.data`
key.

## Include File in Values File
The included file also needs to be referenced from your values file so that the chart knows where to mount the file in the application's Pod:
```yaml
mappedFiles:
  logback.xml:
    path: /home/smile/smilecdr/classes
```
As the result of the above, a `ConfigMap` will be created and mapped into the pod at
`/home/smile/smilecdr/classes/logback.xml` using `Volume` and `VolumeMount` resources. If the
content of the file is changed, then it will be automatically picked up on the next deployment. (See [Automatic Deployment of Config Changes](../updating/#automatic-deployment-of-config-changes) for more info on this)
