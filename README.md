# Smile Digital Health Helm Charts
This repository is the home of the official Smile Digital Health Helm Charts for deploying products in Kubernetes.

## Documentation
Full documentation, including examples, is available at [https://smilecdr-public.gitlab.io/smile-dh-helm-charts](https://smilecdr-public.gitlab.io/smile-dh-helm-charts)
## Current charts available
* [Smile CDR](src/main/charts/smilecdr)
### Pre-Release Versions
Currently the **Smile CDR** chart is in a preview/pre-release state.

It is suitable for evaluation or testing purposes only. Breaking changes may be introduced at any time until the official release of version `1.0.0`.

We appreciate any feedback that can be given to improve upon these charts.
## Installing the charts
To install these charts, you will need to add the Helm repository to your local machine or deployment platform.
### Add and update the Smile Digital Health Helm pre-release repo
```shell
$ helm repo add smiledh-stable https://gitlab.com/api/v4/projects/40759898/packages/helm/stable
$ helm repo update
```
### Quickstart
A Quickstart guide is available in the [chart documentation](https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/quickstart/).
## Changelogs
Changelogs for the charts are available here:
* [Release Changelog](CHANGELOG.md)
* [Pre-release Changelog](CHANGELOG-PRE.md)
