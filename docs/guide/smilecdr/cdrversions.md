# Supported Smile CDR Versions
By default, this Helm Chart supports the latest published version of the Smile CDR docker image.

## Important! Set Your desired Smile CDR Version
If you need to pin to a specific version of Smile CDR, be sure to specify the appropriate value for `cdrVersion` in your values file. If you fail to do this, your deployment may get unexpectedly upgraded when using a newer version of the Helm Chart.

You can configure the Smile CDR version globally as follows:

#### `my-values.yaml`
```yaml
cdrVersion: "2024.11.R05"
```

### `cdrValues` vs `image.tag`
In previous versions of the Helm Chart (< v3.0), the version of Smile CDR was selected directly using `image.tag`.

With V3 and onwards, the Helm Chart now needs to know the version of Smile CDR being deployed, so that it can perform version based feature enablement. Due to this, the `image.tag` is no longer sufficient to accurately determine the correct version, as it's possible to use custom built images that do not follow the same naming scheme.

The latest versions of the Helm Chart now generate `image.tag` based upon the provided (or the default) `cdrVersion`. You should remove `image.tag` from your configuration unless you are using a custom Smile CDR image tag.

If you do need to set `image.tag` directly, the Helm Chart has no way of knowing which version of Smile CDR is being deployed. In this case, the chart will display an error until you also set `cdrVersion`.

## Current Smile CDR Version
### Smile CDR `2024.11.R05`

Versions `v3.0.0` and newer of the chart support the latest production release of Smile CDR - `2024.11.R05` and above.

Please refer to the Smile CDR [changelog](https://smilecdr.com/docs/introduction/changelog.html) for more information on feature changes.

## Version Support Table
For each Smile CDR version, this table shows the **Min** and **Max** Helm Chart version that officially support it.

Each Smile CDR release has a minimum Helm Chart version that is required for official support.

| Smile CDR | Min | Max | Notes |
|-----------|-----------|-----------|-------|
|`2025.05`|`v5.0.0`|-|Future Release|
|`2025.02`|`v4.0.0`|-|Future Release|
|`2024.11`|`v3.0.0`|`v3.x`|Current Release|
|`2024.08`|`v2.0.0`|`v3.x`|[Note 1](#notes)|
|`2024.05`|`v1.0.0`|`v3.x`|[Note 1](#notes)|
|`2024.02`|`v1.0.0-pre.93`|`v3.x`|[Note 1](#notes)|
|`2023.11`|`v1.0.0-pre.93`|`v2.x`|[Note 2](#notes)|
|`2023.08`|`v1.0.0-pre.93`|`v1.x`|[Note 2](#notes)|
|`2023.05`|`v1.0.0-pre.93`|`v1.x`|[Note 2](#notes)|
|`2023.02`|`v1.0.0-pre.52`|`v1.0.0-pre.78`|[Note 3](#notes)|

#### Notes
>**Note 1** If using older version of Smile CDR with Helm Chart V3 or higher, ensure that you have the correct `cdrVersion` value provided.

>**Note 2** If using older version of Smile CDR with Helm Chart V1 or V2, ensure that you have the correct `image.tag` value provided.

>**Note 3** Unsupported beyond the 'Max' version. If using older version of Smile CDR with newer version of the Helm Chart, please see the section below for any compatibility considerations.

## Upgrading
When upgrading from older versions of Smile CDR, there may be some additional required steps.

Changes across multiple versions may be cumulative, so you should perform any upgrade steps one major version (Of Smile CDR) at a time.
