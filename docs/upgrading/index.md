# Upgrading the Helm Chart and Smile CDR

## Choosing Helm Chart Versions
As these Helm Charts follow SemVer 2.0, the version format is `MAJOR.MINOR.PATCH` with an optional suffix depending on the release channel being used (e.g. pre release (`-pre.n`) or next major release (`-next.n`))

!!! note
    It is recommended to always use the latest published version of the Helm Chart.<br>
    Refer to the [Versioning Strategy](./versioning-strategy.md) page for more information on the Helm Chart versions.

## Choosing Smile CDR Versions

Each major version of the Helm Chart supports the following Smile CDR releases at the time of publishing.

* Defaults to the current Smile CDR GA release
* Supports future patch level releases for the current Smile CDR GA release
* Does ***NOT*** support future Smile CDR GA releases
* Supports the previous 4 GA releases

This table shows the current and previous stable releases:

| Helm Chart Version  | Default Smile CDR Version | Max Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------- | ------------------------- | --------------------- | ---------------------------------- |
{{ previous_versions_table }}

*See the [version matrix](./version-matrix.md) for the full list of supported combinations.*

### Pin Your Smile CDR Version

To ensure predictable deployments, you should explicitly set the desired Smile CDR version using the `cdrVersion` value in your Helm values file:

```yaml
cdrVersion: "{{ current_smile_cdr_version }}"
```

!!! note
    Refer to the [version matrix](./version-matrix.md) for details on available versions.

### Future and Unsupported Smile CDR Versions

By default, this Helm Chart restricts version selection to supported Smile CDR GA Releases as shown in the table above.

If you want to use a newer Smile CDR GA Release, you should upgrade to the latest Helm Chart.

### Working with Pre-Release Versions of Smile CDR

When working with Smile Digital Health support to test Pre-Release Smile CDR builds, you may need to use a Helm Chart from a future or preview release channel.

For example, assuming the current Helm Chart version is `{{ current_helm_version }}`, supporting Smile CDR `{{ current_smile_cdr_version }}`, you may find the following versions in alternate channels:

| Helm Chart Version               | Smile CDR Release                     |
| -------------------------------- | ------------------------------------- |
| `{{ next_major_helm_version }}`  | `{{ next_major_smile_cdr_version }}`  |
| `{{ beta_helm_version }}`        | `{{ beta_smile_cdr_version }}`        |
| `{{ alpha_helm_version }}`       | `{{ alpha_smile_cdr_version }}`       |

!!! note
    See the [version matrix](./version-matrix.md#upcoming-release-previews) and the [release channels](./release-channels.md) documentation for more guidance on using alternative release channels.

To use a Smile CDR Pre-Release, you should use a Helm Chart version from one of the preview release channel.

Refer to the [Upcoming Release Previews section of the Version Matrix](./version-matrix.md/#upcoming-release-previews) to find a suitable Helm Chart version and release channel.

### Overriding Version Restrictioon
If you are unable to update your Helm Chart version, or if there is no preview release available for the version of Smile CDR that you wish to use, you can bypass version restrictions by setting `allowUnsupportedCdrVersions: true`:

```yaml
cdrVersion: "2095.02.R01"
allowUnsupportedCdrVersions: true
```

!!! warning
    Using this override may cause issues with some Helm Chart features. Only use it for testing when a compatible Helm Chart is unavailable.

## Using Custom Image Tags

If you're using a custom container repository or non-standard image tags, specify both the Smile CDR version and the custom image tag in your Helm values file:

```yaml
cdrVersion: "{{ current_smile_cdr_version }}"
image:
  tag: my-custom-build-tag
```

!!! note
    Setting an image tag without `cdrVersion` will cause an error. The chart still requires a known version to enable compatibility checks.

## Migration Guides

### `v4.x` to `v5.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v4.x` to `v5.x`.

---

#### Overview of Changes
- Default Smile CDR version updated from `2025.02.R03` to `2025.05.R01`.
- Updated configurations for IAM or Secrets Manager database authentication.

---

#### Actionable Items
##### Check Helm Chart Warnings

Before any upgrade, check the output of your `helm install` command for any warnings.

These warnings may include misconfigurations or deprecation warnings that may affect your upgrade.

??? note "Displaying Helm Chart warnings when deploying with Terraform"
    If deploying using the Terraform `helm_release` resource, you may not see the warnings during deployment as they are not displayed by default.

    In order to check the warnings, you can get the Helm release notes directly like so:
    ```
    helm -n my-namespace list # <- to get list of releases
    helm -n my-namespace get notes <release-name>
    ```

If you see the following output, it is safe to upgrade the Helm Chart
```
***************************
**** NO CHART WARNINGS ****
***************************
```

##### Pin Your Smile CDR Version
**ALWAYS Pin Your Smile CDR Version!**

As a reminder, always [Pin Your Smile CDR Version](#pin-your-smile-cdr-version) when upgrading the Helm Chart, in order to prevent unexpected changes to your Smile CDR release.

!!! warning
    Failure to pin your Smile CDR version ***will*** result in unexpected upgrades to the version of Smile CDR being deployed.

##### Upgrade-related Changes
Review the following action items to address any potentially breaking changes.

###### Updated configurations for IAM or Secrets Manager database authentication.
* Although the required configuration change should take effect without any intervention, logs should be reviewed to ensure that any RDS connections using IAM or Secrets Manager are still working as expected.
* If there are any issues, make sure you have correctly set your Smile CDR version in your values file by setting `cdrVersion` to `2025.05.R01` or higher.
* If you wish to still use the old mechanism, you should pin your Smile CDR version using `cdrVersion` to `2025.02.*` or earlier. See the [version matrix](./version-matrix.md) for more info on supported versions.
* See [here](../guide/smilecdr/database-external.md#using-iam-or-direct-secrets-manager-authentication) for information on configuring IAM authentication.
* See [here](https://smilecdr.com/docs/v/2025.08.PRE/database_administration/rds_auth.html#aws-advanced-jdbc-driver) for information on the associated changes to Smile CDR

No additional changes are required to upgrade from v4.x to v5.0

### `v3.x` to `v4.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v3.x` to `v4.x`.

---

#### Overview of Changes
- Default Smile CDR version updated from `2024.11.xx` to `2025.02.R03`.

---

#### Actionable Items
##### Check Helm Chart Warnings

Before any upgrade, check the output of your `helm install` command for any warnings.

These warnings may include misconfigurations or deprecation warnings that may affect your upgrade.

??? note "Displaying Helm Chart warnings when deploying with Terraform"
    If deploying using the Terraform `helm_release` resource, you may not see the warnings during deployment as they are not displayed by default.

    In order to check the warnings, you can get the Helm release notes directly like so:
    ```
    helm -n my-namespace list # <- to get list of releases
    helm -n my-namespace get notes <release-name>
    ```

If you see the following output, it is safe to upgrade the Helm Chart
```
***************************
**** NO CHART WARNINGS ****
***************************
```

##### Pin Your Smile CDR Version
**ALWAYS Pin Your Smile CDR Version!**

As a reminder, always [Pin Your Smile CDR Version](#pin-your-smile-cdr-version) when upgrading the Helm Chart, in order to prevent unexpected changes to your Smile CDR release.

!!! warning
    Failure to pin your Smile CDR version ***will*** result in unexpected upgrades to the version of Smile CDR being deployed.

##### Upgrade-related Changes
Review the following action items to address any potentially breaking changes.

No additional changes are required to upgrade from v3.x to v4.0

###  `v2.x` to `v3.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v2.x` to `v3.x`.

---

#### Overview of Changes
- Default Smile CDR version updated from `2024.08.R01` to `2024.11.R05`.
- You must now explicitly specify the Smile CDR version in your values file.
- Some chart features are now gated based on the specified Smile CDR version.
- `oldResourceNaming` is now disabled by default.
- `node.environment.type` is now set in the Smile CDR properties file (default: `DEV`) for Smile CDR versions `2024.08.R01` and above.

##### Feature Gates (Informational)
This chart introduces feature gates that enable or disable behavior based on the Smile CDR version. To ensure these features work correctly, the version must be explicitly specified if it differs from the chart default.

---

#### Actionable Items
##### Check Helm Chart Warnings

Before any upgrade, check the output of your `helm install` command for any warnings.

These warnings may include misconfigurations or deprecation warnings that may affect your upgrade.

??? note "Displaying Helm Chart warnings when deploying with Terraform"
    If deploying using the Terraform `helm_release` resource, you may not see the warnings during deployment as they are not displayed by default.

    In order to check the warnings, you can get the Helm release notes directly like so:
    ```
    helm -n my-namespace list # <- to get list of releases
    helm -n my-namespace get notes <release-name>
    ```

If you see the following output, it is safe to upgrade the Helm Chart
```
***************************
**** NO CHART WARNINGS ****
***************************
```

##### Upgrade-related Changes
Review the following action items to address any potentially breaking changes.

###### Specifying Smile CDR Version
Previously, the Smile CDR version was defined using `image.tag`. This is no longer sufficient, especially when using custom tags that do not follow Smile’s versioning scheme.

- **New Requirement:** Use the `cdrVersion` setting instead of `image.tag`.
- If `cdrVersion` is omitted, the chart default will be used, and a warning will be displayed during `helm install` or `helm upgrade`.
- Remove `image.tag` unless using a custom image (see below).

####### Using Custom Image Tags
If you're using custom builds or alternative container registries, you may continue to set `image.tag`, but you **must also** specify the correct `cdrVersion`.

See [Choosing Smile CDR Version](#choosing-smile-cdr-versions) for details.

---

###### Deprecation of `oldResourceNaming`
The `oldResourceNaming` flag now defaults to `false`, in preparation for its removal in a future release.

- If you have already set `oldResourceNaming: false`, no action is needed.
- If not, upgrading will change the names of Kubernetes resources such as services and ingress. Review any dependent resources (e.g., ALB configuration, IAM roles) to ensure compatibility.
- `oldResourceNaming` can still be manually set to `true` if more time is needed to review the changes. Note that it ***WILL*** be removed in a future version of the Helm Chart.

###  `v1.x` to `v2.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v1.x` to `v2.x`.

---

#### Overview of Changes
- Default Smile CDR version updated from `2024.05.R01` to `2024.08.R01`.
- Default context root for the Admin JSON module has changed from `json-admin` to `admin_json`

---

#### Actionable Items
##### Check Helm Chart Warnings

Before any upgrade, check the output of your `helm install` command for any warnings.

These warnings may include misconfigurations or deprecation warnings that may affect your upgrade.

??? note "Displaying Helm Chart warnings when deploying with Terraform"
    If deploying using the Terraform `helm_release` resource, you may not see the warnings during deployment as they are not displayed by default.

    In order to check the warnings, you can get the Helm release notes directly like so:
    ```
    helm -n my-namespace list # <- to get list of releases
    helm -n my-namespace get notes <release-name>
    ```

If you see the following output, it is safe to upgrade the Helm Chart
```
***************************
**** NO CHART WARNINGS ****
***************************
```

##### Pin Your Smile CDR Version
**ALWAYS Pin Your Smile CDR Version!**

In order to prevent unexpected upgrades to Smile CDR when updating the Helm Chart, you should set the Smile CDR version using `image.tag`

!!! warning
    Failure to pin your Smile CDR version ***will*** result in unexpected upgrades to the version of Smile CDR being deployed.

##### Upgrade-related Changes
Review the following action items to address any potentially breaking changes.

###### Admin JSON Context Root
The default context path for the Admin JSON module has been updated to align with the Smile CDR default.

This change does not affect the operation of your Smile CDR deployment. However, if any upstream systems rely on the previous context path, you may need to update them accordingly.

If you have explicitly configured a custom context path for the Admin JSON module, this change will not impact your deployment.

---

###  Pre-Release Versions to `v1.x` or above

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart pre-release versions `v1.0.0-pre.n` to `v1.x` or higher.

---

If you have previously installed Smile CDR using the `1.0.0-pre.x` pre-release versions of the Helm Chart, then you will need to adjust your deployment process to use the `stable` release channel before you can use the officially supported versions.


Please refer to the [Release Channels](./release-channels.md) section for more information on switching release channels.
