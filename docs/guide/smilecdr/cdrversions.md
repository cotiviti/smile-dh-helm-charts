# Supported Smile CDR Versions
By default, this Helm Chart supports the latest published version of the Smile CDR docker image.

> **WARNING** - Pre-release versions of this Helm Chart may default to pre-release versions of Smile CDR

## Current Version
Versions `v1.0.0-pre.52` and newer of the chart support the latest production release of Smile CDR - `2023.02.R03`.

This version included some major changes from previous versions that cause some incompatibility.

* Pod is now configured with an enhanced security posture
    * Containers now run as non-root user
    * Root filesystem is mounted read-only
    * Extra ephemeral volumes are used for certain directories that need write access
      e.g. logs, tmp
* New Audit logging mechanism introduced that optionally utilizes separate database
* Licencing module introduced

## Previous Versions
In order to run Smile CDR versions `2022.11` and earlier with this Helm Chart, you will need to make some extra configurations in your Helm values file.

* Disable running as non-root user
* Disable Audit and License modules
* Set the image tag

As with any version of Smile CDR that you use with this Helm Chart, part of the deployment process is developing a set of Helm Values that works for your particular use case. This does not change that, but these settings may need to be added/changed if you already have a versions file that you have developed.

### Disable Running as non-root User
In order to do this, we must override the `podSecurityContext` that is defined in the default `values.yaml` file in the Helm Chart.

#### Default `values.yaml`
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

#### Required additions to `my-values.yaml` to re-enable running as root
```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
```

> **Note** - You do not need to disable the capabilities dropping or the read only root file-system as previous versions of Smile CDR still function with these security enhancements in place.

### Disable Audit and License modules
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

### Set Image Tag
Set `image.tag` to your required version

#### `my-values.yaml`
```yaml
image:
  tag: "2022.11.R04"
```

> **Warning** Do not forget this step when using this Helm Chart to update an existing installation that is running a previous version of Smile CDR.</br>Doing so may automatically upgrade your database to the latest version. If you then revert back to the previous version, it may not function correctly with the updated DB schema.
