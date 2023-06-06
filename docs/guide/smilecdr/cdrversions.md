# Supported Smile CDR Versions
By default, this Helm Chart supports the latest published version of the Smile CDR docker image.

## Important! Set Your Image Tag
If you need to pin to a specific version of Smile CDR, be sure to specify the appropriate value for `image.tag` in your values file. If you fail to do this, your deployment may get unexpectedly upgraded when using a newer version of the Helm Chart.

Set `image.tag` to your required version

#### `my-values.yaml`
```yaml
image:
  tag: "2023.05.R01"
```

> **Warning** Pre-release versions of this Helm Chart may default to pre-release versions of Smile CDR. Always update the image tag when using this Helm Chart to update an existing installation that is running a previous version of Smile CDR.</br>If you do not perform this step, Smile CDR may automatically upgrade your database to the latest version, which may be an irreversible step!

## Current Smile CDR Version
### Smile CDR `2023.05.R01`

Versions `v1.0.0-pre.80` and newer of the chart support the latest production release of Smile CDR - `2023.05.R01`.

This version includes some significant changes from previous versions that may cause some incompatibility. The following changes have been included in this version of the Helm Chart.

* New Transaction logging mechanism introduced that utilizes separate database
* Fhir Endpoint module now uses `ENDPOINT_FHIR_REST` instead of `ENDPOINT_FHIR_REST_R4`. This is a backwards-compatible change.

### Upgrading

If you are upgrading from `v1.0.0-pre.78` (Smile CDR `2023.02.R03`) or earlier you will need to do the following steps beforehand:

* Provision a database for the `transaction` module.
* Configure the transaction module credentials in your values file.

## Previous Smile CDR Versions

If you need to run an older version of Smile CDR with the current version of the Helm Chart, you may need to override some configurations in your Helm values file.

### Smile CDR `2023.02.R03`

If you wish to continue to use Smile CDR `2023.02.R03` with Versions `v1.0.0-pre.80` or greater, then you will need to do the following before using the newer chart:

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

### Smile CDR `2021.11.*`

In order to run Smile CDR versions `2022.11` and earlier with this Helm Chart, you will need to make some extra configurations in your Helm values file.

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

#### Disable Audit and License modules
In order to disable default modules, you need to set ```useDefaultModules``` to false. See [here](./modules.md#disabling-included-default-module-definitios) for more info.

Then you need to explicityly define ALL modules that you need to configure.

#### `my-values.yaml`
```yaml
modules:
  useDefaultModules: false
  clustermgr:
    ...
```
> **Note** See examples section for a [complete configuration showing this](../../examples/previousrootversion.md).
