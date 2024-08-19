# Upgrading the Helm Chart and Smile CDR

## Upgrading From Pre-Release Versions
If you have installed Smile CDR using pre-release versions of the Helm Charts, then you will need to adjust your deployment process to use the `STABLE` release channel before you can use the officially supported versions.

Please refer to the [Release Channels](./release-channels.md) section for more information on switching release channels.

## Upgrading Helm Chart Versions
As per the [Helm Best Practices](https://helm.sh/docs/chart_best_practices/) guidelines, the Smile CDR Helm Chart adheres to the [Semantic Versioning 2.0](https://semver.org/) specification.

This means that:

* The version number is in the format `MAJOR.MINOR.PATCH`
* **PATCH** level changes will only include bug fixes.
    * This may also include big fixes for upstream components such as Smile CDR itself.
* **MINOR** level changes will only include non-breaking feature updates.
    * This only relates to features in the Helm Chart, not in the core Smile CDR product.
* **MAJOR** level changes will include potentially breaking feature updates.
    * This relates to breaking features in the Helm Chart.
    * This will also include any new Smile CDR major releases.

## Upgrading Smile CDR Versions
Although each version of the Helm Chart will default to a specific version of Smile CDR, it is often desirable to explicitly define the Smile CDR version so that you can be in more direct control of any upgrades that take place.

You can override the version of Smile CDR by adjusting the `image.tag` in your Helm values file. i.e:

```
image:
  tag: "{{ current_smile_cdr_version }}"
```

### Smile CDR Version Compatibility
In general, when installing a current version of Smile CDR, we recommend you use the latest version of the Helm Chart. Each new version of the Helm Chart will support the previous 4 major versions of Smile CDR. e.g:

| Helm Chart Version | Default Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------ | ------------------------- | ---------------------------------- |
| v2.0.0             | `2024.08.R01`             | `2023.08.R10`                      |
| v1.0.0             | `2024.05.R03`             | `2023.05.R03`                      |

>**Note:** When explicitly specifying a Smile CDR version, please refer to the full [version matrix](?) to ensure compatibility for the version combination you require.

### Using Pre-Release versions of Smile CDR
On occasion, you may be working directly with Smile Digital Health support to deploy or test ***pre-release*** versions of Smile CDR.

Due to the nature of such releases, breaking changes may cause incompatibility with current versions of the Helm Chart. When such situations occur, you may need to switch back to the pre-release/`DEVEL` Helm repo channel to use a pre-release version of the Helm Chart that will work with the pre-release version of Smile CDR.

Please refer to the pre-releases section of the [version matrix](?) to see if there is a suitable version available, and the [Release Channels](./release-channels.md) section for more information on switching release channels.
