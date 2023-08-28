# Supported Smile CDR Versions
By default, this Helm Chart supports the latest published version of the Smile CDR docker image.

## Important! Set Your Image Tag
If you need to pin to a specific version of Smile CDR, be sure to specify the appropriate value for `image.tag` in your values file. If you fail to do this, your deployment may get unexpectedly upgraded when using a newer version of the Helm Chart.

Set `image.tag` to your required version

#### `my-values.yaml`
```yaml
image:
  tag: "2023.05.R02"
```

> **Warning** Pre-release versions of this Helm Chart may default to pre-release versions of Smile CDR. Always update the image tag when using this Helm Chart to update an existing installation that is running a previous version of Smile CDR.</br>If you do not perform this step, Smile CDR may automatically upgrade your database to the latest version, which may be an irreversible step!

## Current Smile CDR Version
### Smile CDR `2023.08`

Versions `v1.0.0-pre.92` and newer of the chart support the latest production release of Smile CDR - `2023.08.R01` and above.

This version does not contain any changes that affect the Helm Chart.

Please refer to the Smile CDR [changelog](https://smilecdr.com/docs/introduction/changelog.html) for more information on feature changes.

## Version Support Table
For each Smile CDR version, this table shows the **Min** and **Max** Helm Chart version that officially support it.

Older Smile CDR versions will not work beyond the chart version in the **Extra** column - see the notes.

| Smile CDR | Min | Max | Extra | Notes |
|-----------|-----------|-----------|-----------|-------|
|`2023.11.*`|tbd|tbd|tbd||
|`2023.08.R01`|`v1.0.0-pre.92`|tbd|tbd||
|`2023.05.R02`|`v1.0.0-pre.80`|`v1.0.0-pre.91`|tbd|[Note 1](#notes)|
|`2023.02.R03`|`v1.0.0-pre.52`|`v1.0.0-pre.78`|tbd|[Note 2](#notes)|

### Notes
>**Note 1** If using older version of Smile CDR with newer version of the Helm Chart, ensure that you have the correct `image` value provided.

>**Note 2** Unsupported beyond the 'Max' version. If using older version of Smile CDR with newer version of the Helm Chart, please see the section below for any compatibility considerations.

## Upgrading
When upgrading from older versions of Smile CDR, there may be some additional required steps.

Changes across multiple versions may be cumulative, so you should perform any upgrade steps one major version (Of Smile CDR) at a time.

### Smile CDR `2023.05` (Helm Chart version < `v1.0.0-pre.91`)

* There are currently no known required changes.
### Smile CDR `2023.02` (Helm Chart version < `v1.0.0-pre.78`)

* Provision a database for the `transaction` module, or disable the new module in your values file.
* Configure the transaction module credentials in your values file.
* Update your FHIR Endpoint module type to `ENDPOINT_FHIR_REST`, as the `ENDPOINT_FHIR_REST_R4` module has been deprecated
   * Update the dependency type from `PERSISTENCE_R4` to `PERSISTENCE_ALL`

## Previous Smile CDR Versions

### Smile CDR `2023.05`

Versions `v1.0.0-pre.80` and newer of the chart support the latest production release of Smile CDR - `2023.05.R01` and above.

This version includes some significant changes from previous versions that may cause some incompatibility. The following changes have been included in this version of the Helm Chart.

* New Transaction logging module introduced that utilizes separate database
* Fhir Endpoint module now uses `ENDPOINT_FHIR_REST` instead of `ENDPOINT_FHIR_REST_R4`. This is a backwards-compatible change.

If you wish to continue to use Smile CDR `2023.05.*` with Versions `v1.0.0-pre.92` or greater, then you will need to do the following before using the newer chart:
* Include the appropriate image tag in `values.image.tag` (e.g. `2023.05.R02`)
### Smile CDR `2023.02`

If you wish to continue to use Smile CDR `2023.02.*` with Versions `v1.0.0-pre.80` or greater, then you will need to do the following before using the newer chart:

* Disable the `transaction` module
* Revert the `fir_endpoint` module `type` to `ENDPOINT_FHIR_REST_R4`
* Include the appropriate image tag in `values.image.tag` (e.g. `2023.02.R03`)

Versions `v1.0.0-pre.52` to `v1.0.0-pre.78` of the chart natively support the previous production release of Smile CDR - `2023.02.R03`.

This version included some major changes from previous versions that cause some incompatibility.

* Pod is now configured with an enhanced security posture
    * Containers now run as non-root user
    * Root filesystem is mounted read-only
    * Extra ephemeral volumes are used for certain directories that need write access
      e.g. logs, tmp
* New Audit logging mechanism introduced that optionally utilizes separate database
* Licencing module introduced

### Smile CDR `2022.11`

It is not recommended to run Smile CDR versions `2022.11` and earlier with this Helm Chart due to a number of security changes. To do so, you will need to make some configuration changes in your Helm values file to disable some of the security features.

* Disable running as non-root user
* Disable Audit and License modules
* Set the image tag

As with any version of Smile CDR that you use with this Helm Chart, part of the deployment process is developing a set of Helm Values that works for your particular use case. This does not change that, but these settings may need to be added/changed if you already have a versions file that you have developed.

#### Disable Running as non-root User
In order to do this, we must override the `podSecurityContext` that is defined in the default `values.yaml` file in the Helm Chart.

##### Default `values.yaml`
```yaml
securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  privileged: false
  allowPrivilegeEscalation: false
```

##### Required additions to `my-values.yaml` to re-enable running as root
```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
```

> **Note** - You do not need to disable the capabilities dropping or the read only root file-system as previous versions of Smile CDR still function with these security enhancements in place.

#### Disable Unsupported modules
In order to disable all default modules, you need to set ```useDefaultModules``` to false. See [here](./modules.md#disabling-included-default-module-definitios) for more info.

Then you need to explicityly define ALL modules that you need to configure.

#### `my-values.yaml`
```yaml
modules:
  useDefaultModules: false
  clustermgr:
    ...
```
> **Note** See examples section for a [complete configuration showing this](../../examples/previousrootversion.md).
