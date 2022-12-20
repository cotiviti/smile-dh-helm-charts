# Smile Digital Health Helm Charts
This repository is the home of the official Smile Digital Health Helm Charts for deploying products in Kubernetes.
## Current charts available
* [Smile CDR](src/main/charts/smilecdr)
### Pre-Release Versions
Currently the **Smile CDR** chart is in a preview/pre-release state.

It is suitable for evaluation or testing purposes only. Breaking changes may be introduced at any time until the official release of version `1.0.0`

We appreciate any feedback that can be given to improve upon these charts.
## Installing the charts
To install these charts, you will need to add the Helm repository to your local machine.
### Add and update the Smile Digital Health Helm pre-release repo
```shell
$ helm repo add smiledh https://gitlab.com/api/v4/projects/40759898/packages/helm/devel
$ helm repo update
```
### Install the latest pre-release version of the chart
```shell
$ helm upgrade -i my-smile-env --devel -f my-values.yaml smiledh/smilecdr
```
> **NOTE**: You cannot install these charts without first installing some dependencies and creating a
values file for your environment. Please consult the [chart documentation](src/main/charts/smilecdr/README.md#installation) for information on how to
do this.
## Changelogs
Changelogs for the charts are available here:
* [Release Changelog](CHANGELOG.md)
* [Pre-release Changelog](CHANGELOG-PRE.md)
