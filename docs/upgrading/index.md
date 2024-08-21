# Upgrading the Helm Chart and Smile CDR

## Upgrading From Pre-Release Versions
If you have installed Smile CDR using pre-release versions of the Helm Charts, then you will need to adjust your deployment process to use the `STABLE` release channel before you can use the officially supported versions.

Please refer to the [Release Channels](./release-channels.md) section for more information on switching release channels.

## Choosing Helm Chart Versions
As these Helm Charts follow SemVer 2.0, the version format is ``MAJOR.MINOR.PATCH`` with an optional suffix for pre-release (``-pre.n``) or beta (``-beta.n``) versions

Refer to the [Versioning Strategy](../upgrading/versioning-strategy.md) page for more information.

## Choosing Smile CDR Versions
Although each version of the Helm Chart will default to a specific version of Smile CDR, it is often desirable to explicitly define the Smile CDR version so that you can be in more direct control of any upgrades that take place.

!!! note
    Any version of Smile CDR can be specified as long as it falls within the range of supported versions for the Helm Chart version you are using.<br>
    See the [version compatibility](#smile-cdr-version-compatibility) section and the [version matrix](./version-matrix.md).

You can override the version of Smile CDR by adjusting the `image.tag` in your Helm values file. i.e:

```yaml
image:
  tag: "{{ current_smile_cdr_version }}"
```

### Smile CDR Version Compatibility
In general, when installing a current version of Smile CDR, we recommend you use the latest version of the Helm Chart. Each new version of the Helm Chart will support the previous 4 major versions of Smile CDR. e.g:

| Helm Chart Version | Default Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------ | ------------------------- | ---------------------------------- |
| v2.0.0             | `2024.08.R01`             | `2023.08.R10`                      |
| v1.0.0             | `2024.05.R03`             | `2023.05.R03`                      |

!!! note
    When explicitly specifying a Smile CDR version, please refer to the full [version matrix](./version-matrix.md) to ensure compatibility for the version combination you require.

### Using Pre Release Versions of Smile CDR
On occasion, you may be working directly with the Smile Digital Health support teams to deploy or test pre release versions of Smile CDR.

Due to unforeseen changes in future versions of Smile CDR, there may be compatibility issues with the current version of the Helm Chart.

When such situations occur, you may need to switch to the `DEVEL` release channel to use a pre release or beta version of the Helm Chart that will work with the Pre-Release version of Smile CDR that you are attempting to use.

Typically, if the current Helm Chart version is `{{ current_helm_version }}` (Which uses Smile CDR `{{ current_smile_cdr_version }}`), then the following versions would be available in the `DEVEL` release channel.

| Smile CDR Pre-Release Version | Helm Chart Version |
| - | - |
| `{{ next_smile_cdr_version }}` | `{{ next_helm_major_version }}-beta.1` |
| `{{ next_plus_1_smile_cdr_version }}` | `{{ next_plus_1_helm_major_version }}-beta.1` |

!!! note
    Refer to the pre releases and beta sections of the [version matrix](./version-matrix.md#upcoming-release-previews) to see if there is a suitable Helm Chart version available in the `DEVEL` release channel.

    Refer to [Release Channels](./release-channels.md) for more information on switching release channels.
