# Upgrading the Helm Chart and Smile CDR

## Choosing Helm Chart Versions
As these Helm Charts follow SemVer 2.0, the version format is `MAJOR.MINOR.PATCH` with an optional suffix depending on the release channel being used (e.g. pre release (`-pre.n`) or next major release (`-next.n`))

Refer to the [Versioning Strategy](../upgrading/versioning-strategy.md) page for more information.

## Choosing Smile CDR Versions
Each major version of the Smile CDR Helm Chart defaults to the latest Smile CDR GA release at the time of publishing.

To avoid unexpected changes in Smile CDR version when upgrading the Helm Chart, you should explicitly configure the required version.

!!! note
    Any version of Smile CDR can be specified as long as it falls within the range of supported versions for the Helm Chart version you are using.<br>
    See the [version compatibility](#smile-cdr-version-compatibility) section and the [version matrix](./version-matrix.md).

You should override the default version of Smile CDR used by the Helm Chart by adding `cdrVersion` in your Helm values file. i.e:

```yaml
cdrVersion: "{{ current_smile_cdr_version }}"
```

## Using Custom Image Tags
By default, the Helm Chart will select the correct Smile CDR image from the official container repository based on the provided Smile CDR version. If you are using a different image repository, your tags may not match the upstream versions.

In this case, you must still specify the Smile CDR version in addition to providing your image tag in your Helm values file. i.e.:

```yaml
cdrVersion: "{{ current_smile_cdr_version }}"
image:
  tag: my-custom-build-tag
```

!!! note
    If you specify an image tag without providing `cdrVersion`, the Helm Chart will display an error.

### Smile CDR Version Compatibility
In general, when installing a current version of Smile CDR, we recommend you use the latest version of the Helm Chart. Each new version of the Helm Chart will support the previous 4 Smile CDR GA releases e.g:

| Helm Chart Version | Default Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------ | ------------------------- | ---------------------------------- |
| v3.0.0             | `2024.11.R05`             | `2023.11.R06`                      |
| v2.0.0             | `2024.08.R01`             | `2023.08.R10`                      |
| v1.0.0             | `2024.05.R03`             | `2023.05.R03`                      |

!!! note
    When explicitly specifying a Smile CDR version, please refer to the full [version matrix](./version-matrix.md) to ensure compatibility for the version combination you require.

### Using Pre Release Versions of Smile CDR
On occasion, you may be working directly with the Smile Digital Health support teams to deploy or test Pre-Release versions of Smile CDR.

Due to unforeseen changes in future versions of Smile CDR, there may be compatibility issues with the current version of the Helm Chart.

When such situations occur, you may need to switch to another release channel to use a pre release or beta version of the Helm Chart that will work with the Pre-Release version of Smile CDR that you are attempting to use.

Typically, if the current Helm Chart version is `{{ current_helm_version }}` (Smile CDR `{{ current_smile_cdr_version }}`), then the following versions would be available in other release channels.

| Helm Chart Version | Smile CDR Pre-Release Version |
| - | - |
| `{{ next_helm_major_version }}-beta.1` | `{{ next_smile_cdr_version }}` |
| `{{ next_plus_1_helm_major_version }}-alpha.1` | `{{ next_plus_1_smile_cdr_version }}` |

!!! note
    Refer to the prerelease sections of the [version matrix](./version-matrix.md#upcoming-release-previews) to see if there is a suitable Helm Chart version available.

    Refer to [Release Channels](./release-channels.md) for more information on selecting and switching release channels.


## Upgrading from `v2.x` to `v3.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v2.x` to `v3.x`.

---

### Overview of Changes
- Default Smile CDR version updated from `2024.08.R01` to `2024.11.R05`.
- You must now explicitly specify the Smile CDR version in your values file.
- Some chart features are now gated based on the specified Smile CDR version.
- `oldResourceNaming` is now disabled by default.
- `node.environment.type` is now set in the Smile CDR properties file (default: `DEV`) for Smile CDR versions `2024.08.R01` and above.

#### Feature Gates (Informational)
This chart introduces feature gates that enable or disable behavior based on the Smile CDR version. To ensure these features work correctly, the version must be explicitly specified if it differs from the chart default.

---

### Actionable Items
Review the following action items to address any potentially breaking changes.

#### Specifying Smile CDR Version
Previously, the Smile CDR version was defined using `image.tag`. This is no longer sufficient, especially when using custom tags that do not follow Smile’s versioning scheme.

- **New Requirement:** Use the `cdrVersion` setting instead of `image.tag`.
- If `cdrVersion` is omitted, the chart default will be used, and a warning will be displayed during `helm install` or `helm upgrade`.
- Remove `image.tag` unless using a custom image (see below).

##### Using Custom Image Tags
If you're using custom builds or alternative container registries, you may continue to set `image.tag`, but you **must also** specify the correct `cdrVersion`.

See [Choosing Smile CDR Version](#choosing-smile-cdr-version) for details.

---

#### Deprecation of `oldResourceNaming`
The `oldResourceNaming` flag now defaults to `false`, in preparation for its removal in a future release.

- If you have already set `oldResourceNaming: false`, no action is needed.
- If not, upgrading will change the names of Kubernetes resources such as services and ingress. Review any dependent resources (e.g., ALB configuration, IAM roles) to ensure compatibility.
- `oldResourceNaming` can still be manually set to `true` if more time is needed to review the changes. Note that it ***WILL*** be removed in a future version of the Helm Chart.

## Upgrading from `v1.x` to `v2.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v1.x` to `v2.x`.

---

### Overview of Changes
- Default Smile CDR version updated from `2024.05.R01` to `2024.08.R01`.
- Default context root for the Admin JSON module has changed from `json-admin` to `admin_json`

---

### Actionable Items
Review the following action items to address any potentially breaking changes.

#### Specifying Smile CDR Version
In order to prevent unexpected upgrades to Smile CDR when updating the Helm Chart, you should set the Smile CDR version using `image.tag`

#### Admin JSON Context Root
The default context path for the Admin JSON module has been updated to align with the Smile CDR default.

This change does not affect the operation of your Smile CDR deployment. However, if any upstream systems rely on the previous context path, you may need to update them accordingly.

If you have explicitly configured a custom context path for the Admin JSON module, this change will not impact your deployment.

---

## Upgrading From Pre-Release Versions to `v1.x` or above

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart pre-release versions `v1.0.0-pre.n` to `v1.x` or higher.

---

If you have previously installed Smile CDR using the `1.0.0-pre.x` pre-release versions of the Helm Chart, then you will need to adjust your deployment process to use the `stable` release channel before you can use the officially supported versions.


Please refer to the [Release Channels](./release-channels.md) section for more information on switching release channels.