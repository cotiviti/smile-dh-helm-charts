# Supported Smile CDR Versions
By default, this Helm Chart supports the latest published version of the Smile CDR docker image.

## Important! Set Your Image Tag
If you need to pin to a specific version of Smile CDR, be sure to specify the appropriate value for `image.tag` in your values file. If you fail to do this, your deployment may get unexpectedly upgraded when using a newer version of the Helm Chart.

Set `image.tag` to your required version

#### `my-values.yaml`
```yaml
image:
  tag: "2024.05.R03"
```

> **Warning** Pre-release versions of this Helm Chart (In the `devel` channel) may default to pre-release versions of Smile CDR. Always update the image tag when using this Helm Chart to update an existing installation that is running a previous version of Smile CDR.</br>If you do not perform this step, Smile CDR may automatically upgrade your database to the latest version, which may be an irreversible step!

## Current Smile CDR Version
### Smile CDR `2024.05.R04`

Versions `v1.0.0` and newer of the chart support the latest production release of Smile CDR - `2024.05.R03` and above.

### Smile CDR `2023.08`

Versions `v1.0.0-pre.92` and newer of the chart support the latest production release of Smile CDR - `2023.08.R01` and above.

Please refer to the Smile CDR [changelog](https://smilecdr.com/docs/introduction/changelog.html) for more information on feature changes.

## Version Support Table
For each Smile CDR version, this table shows the **Min** and **Max** Helm Chart version that officially support it.

Older Smile CDR versions will not work beyond the chart version in the **Extra** column - see the notes.

| Smile CDR | Min | Max | Extra | Notes |
|-----------|-----------|-----------|-----------|-------|
|`2024.11`|`v3.0.0`|tbd|tbd|Future Release|
|`2024.08`|`v2.0.0`|tbd|tbd|Future Release|
|`2024.05`|`v1.0.0`|tbd|tbd|[Note 1](#notes)|
|`2024.02`|`v1.0.0`|tbd|tbd|[Note 1](#notes)|
|`2023.11`|`v1.0.0`|tbd|tbd|[Note 1](#notes)|
|`2023.08`|`v1.0.0`|tbd|tbd|[Note 1](#notes)|
|`2023.05`|`v1.0.0`|tbd|tbd|[Note 1](#notes)|
|`2023.02`|`v1.0.0-pre.52`|`v1.0.0-pre.78`|tbd|[Note 2](#notes)|

#### Notes
>**Note 1** If using older version of Smile CDR with newer version of the Helm Chart, ensure that you have the correct `image` value provided.

>**Note 2** Unsupported beyond the 'Max' version. If using older version of Smile CDR with newer version of the Helm Chart, please see the section below for any compatibility considerations.

## Upgrading
When upgrading from older versions of Smile CDR, there may be some additional required steps.

Changes across multiple versions may be cumulative, so you should perform any upgrade steps one major version (Of Smile CDR) at a time.
