# Versioning Strategy
The Smile CDR Helm Chart follows the [Semantic Versioning 2.0](https://semver.org/) specification as per the [Helm Best Practices](https://helm.sh/docs/chart_best_practices/) guidelines.

## Version Format

The Smile CDR Helm Chart version number uses the following format

`MAJOR.MINOR.PATCH`

>Note: The version can optionally include a prerelease suffix (e.g. `-pre.n` or `-next.n`).

## Release Types
The Helm Charts follow a different versioning specification to the core Smile CDR product, which uses [Calendar Versioning]().

>Refer to the [Smile CDR docs](https://smilecdr.com/docs/v/2025.08.PRE/versions_and_upgrading/versioning.html#a-primer-on-smile-cdr-versioning) for more information on the Smile CDR versioning specification.

Due to the differences in versioning schema, the Smile CDR Helm Chart versions are mapped to the core product versions as follows.

### Major Releases
Major releases of the Smile CDR Helm Chart occur every 3 months, aligned with the upstream Smile CDR GA releases [schedule](https://smilecdr.com/docs/v/2025.08.PRE/versions_and_upgrading/versioning.html#release-cadence).

* Aligned with new [Generally Available](https://smilecdr.com/docs/v/2025.08.PRE/versions_and_upgrading/versioning.html#generally-available) releases of Smile CDR
* The `MAJOR` version number is incremented
* The `MINOR` and `PATCH` version numbers are set to zero
* Includes any new breaking features or fixes that could not be included in the previous major release
* For example, version `{{ current_helm_version }}` defaults to Smile CDR `{{ current_smile_cdr_version }}`, and version `{{ next_major_helm_version }}` will default to Smile CDR `{{ next_major_smile_cdr_version }}`.

### Minor Releases
Minor releases of the Smile CDR Helm Chart may occur whenever new non-breaking features are released.

* The `MAJOR` version number remains unchanged
* The `MINOR` version number is incremented
* The `PATCH` version number is set to zero
* Includes any new non-breaking features
* May also included bundled new non-breaking fixes

### Patch Releases
Patch releases of the Smile CDR Helm Chart may occur whenever new non-breaking fixes are released.

* The `MAJOR` and `MINOR` version numbers remain unchanged
* The `PATCH` version number is incremented
* Includes any new non-breaking fixes
* Includes changes in the patch level of Smile CDR.
* For example, version `1.1.0` uses Smile CDR `2024.05.R03`, and version `1.1.1` uses `2024.05.R04`.

### Pre Releases
Pre-releases of the Smile CDR Helm Chart may occur prior to minor or patch level releases for the current stable major release

* Named in the format `MAJOR.MINOR.PATCH-pre.n`, where `MAJOR.MINOR.PATCH` represents the version being previewed, and `n` is the pre release number.
* Incremental pre-releases before a minor or patch version update (e.g. upgrading from version `1.2.0-pre.5` to version `1.2.0-pre.6`) may include breaking changes.
* Used for testing and collaboration on new features for the current major release.
* Are ***not*** published to the stable release channel. You must configure the `pre-release` channel to use pre release versions of the Helm Chart. See [here](release-channels.md)

### Next Major Releases
Next-major releases of the Smile CDR Helm Chart may occur prior to future major releases

* Named in the format `MAJOR.MINOR.PATCH-next.n`, where `MAJOR.MINOR.PATCH` represents the next major version being previewed, and `n` is the pre release number for the upcoming major release.
* Incremental pre-releases before a minor or patch version update (e.g. upgrading from version `2.0.0-pre.1` to version `2.0.0-pre.2`) may include breaking changes.
* Used for testing and collaboration on new features for the next major release, `n+1`
* Are ***not*** published to the stable release channel. You must configure the `next-major` channel to use pre release versions of the Helm Chart. See [here](release-channels.md)
<!-- * After `2.1.0` is released, any future `3.x` pre-releases will not contain breaking changes. -->

### Beta Releases
Beta releases of the Smile CDR Helm Chart may occur prior to future major releases

* Named in the format `MAJOR.MINOR.PATCH-beta.n`, where `MAJOR.MINOR.PATCH` represents the major version in beta, and `n` is the beta release number.
* Incremental beta releases before a major version update (e.g. upgrading from version `3.0.0-beta.2` to version `3.0.0-beta.3`) may include breaking changes.
* Used for testing and collaboration on new features for a future major release, `n+2`
* Are ***not*** published to the stable release channel. You must configure the `beta` channel to use pre release versions of the Helm Chart. See [here](release-channels.md)
<!-- * After `2.0.0` is released, future `3.x` minor or patch level releases will be developed on the `next` releases, starting at `3.0.0-next.1` -->

### Alpha Releases
Alpha releases of the Smile CDR Helm Chart may occur prior to future major releases

* Named in the format `MAJOR.MINOR.PATCH-alpha.n`, where `MAJOR.MINOR.PATCH` represents the major version in alpha, and `n` is the alpha release number.
* Incremental alpha releases before a major version update (e.g. upgrading from version `4.0.0-beta.1` to version `4.0.0-beta.2`) may include breaking changes.
* Used for testing and collaboration on new features for a future  major release, `n+3`
* Are ***not*** published to the stable release channel. You must configure the `alpha` channel to use pre release versions of the Helm Chart. See [here](release-channels.md)
<!-- * After `2.0.0` is released, future `4.x` minor or patch level releases will be developed on the `beta` releases, starting at `4.0.0-beta.1` -->

## Breaking Change Features
If a new Helm Chart feature or fix includes a breaking change, then it will cause a bump in the major version number.

In order to maintain alignment with the Smile CDR GA releases, any new features with breaking changes will be released along with the next Major version of Smile CDR

## Back Porting Features
As new features are developed on the current and future versions of the Helm Chart, they may not be available on previous versions.

If you need to use a new feature, it is strongly recommended to update to the latest major version of the Helm Chart. Back-porting of features to previous versions of the Helm Chart will be considered on an individual basis.

<!-- ### Critical Bug Fixes
Any critical bug or security fixes will be back-ported to the previous 4 major versions of the Helm Chart if it is technically feasible to do so. -->
