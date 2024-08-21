# Branching Strategy and Versioning Workflow for Smile CDR Helm Charts

This document outlines the versioning strategy and branching workflow for the Smile CDR Helm Charts.

The workflow is based on the semantic-release [workflow](https://semantic-release.gitbook.io/semantic-release/recipes/release-workflow) but has been modified to work in conjunction with the Smile CDR release process.

This branching workflow aligns with Semantic Release guidelines and integrates with the CI pipeline for automated versioning and release management.

## Versioning
As these Helm Charts follow SemVer 2.0, the version format is ``MAJOR.MINOR.PATCH`` with an optional suffix for pre release (``-pre.n``) or beta (``-beta.n``) versions

Refer to the [Versioning Strategy](../upgrading/versioning-strategy.md) page for more information.

## Branch and Flow Overview

The following branches are used to auto-publish releases to the `STABLE` release channel:

| Branch | Release Format | Usage |
| - | - | - |
| `main` | `MAJOR.MINOR.PATCH` | The current stable production-ready release |
| `release-n.x` | `MAJOR.MINOR.PATCH` | Used for maintaining stable updates for previous `n.x` production releases. Only created after the release of the 'n+1' version |

The following branches are used to auto-publish pre releases and beta versions to the `DEVEL` release channel:

| Branch | Release Format | Usage |
| - | - | - |
| `pre-release` | `MAJOR.MINOR.PATCH-pre.n` | Used for developing non-breaking changes on the current release |
| `pre-release-n.x` | `MAJOR.MINOR.PATCH-pre.n` | Used for previewing maintenance updates for the `release-n.x` branches. |
| `next` | `MAJOR.MINOR.PATCH-beta.n` | Used for ongoing development of the next upcoming major release |
| `next-n.x` | `MAJOR.MINOR.PATCH-beta.n` | Used for developing and previewing releases beyond the next release |

Features get developed in their own feature branches and should be merged into one of the branches above

### Branch Flow for Release and Maintenance Branches
The bulk of Helm Chart features and fixes are developed for the current stable release of the Helm Chart.

* Development is performed on a feature branch which is then merged into the `pre-release` branch
    * This merge will automatically create the next minor/patch pre release in the `DEVEL` channel.
* To publish an official release, the repo maintainer creates a merge request from `pre-release` into `main`
    * This merge will automatically create the next official minor/patch release in the `STABLE` channel.
* Fixes (and optionally, features) can be back ported to previous releases using the `release-n.x` maintenance branches

The below Git workflow demonstrates this process, assuming that we start out with version `1.0.0` being the current stable release.

```mermaid
---
config:
  gitGraph:
    parallelCommits: true
---
gitGraph TB:
    checkout main
    commit id: "v1.0.0"
    branch release-1.x order: 4
    checkout main
    commit id: "v2.0.0"
    branch pre-release order: 1
    branch v2-feat-1 order: 2
    commit id: "feat: add new v2 feature"
    checkout pre-release
    merge v2-feat-1
    commit id: "Bump v2.1.0-pre.1"
    checkout main
    merge pre-release
    commit id: "Bump v2.1.0"
    checkout pre-release
    merge main id: "mergeback"

    checkout release-1.x
    branch v1-fix-1 order: 5
    commit id: "fix: fix v1"
    checkout release-1.x
    merge v1-fix-1
    commit id: "Bump v1.1.1"

    #checkout pre-release
    #branch general-fix order: 3
    #commit id: "fix: fix for all versions"
    #checkout pre-release
    #merge general-fix
    #commit id: "Bump v2.1.1-pre.1"
    #checkout main
    #merge pre-release
    #commit id: "Bump v2.1.1"

    #checkout release-1.x
    #merge general-fix id: "Backport Fix"
    #commit id: "Bump v1.1.2"

```

### Branch Flow for Next and Future Versions
Some Helm Chart features and fixes contain breaking changes need to be developed for a future major release of the Helm Chart. This can occur when:

* The chart is updated to use the next major Smile CDR release
* The feature or fix contains a breaking change that cannot be implemented in a backwards compatible fashion

The development process is the same as the regular [branch flow above](#branch-flow-for-release-and-maintenance-branches), except different branches are used:

* Development is performed on a feature branch which is then merged into the `next` or `next-n.x` branch.
    * This merge will automatically create the next major beta release in the `DEVEL` channel.
* To initiate an official major release, the repo maintainer creates a merge request from `next` into `pre-release`
    * This merge will automatically create the next major pre release in the `DEVEL` channel.
* To complete an official major release, the repo maintainer creates a merge request from `pre-release` into `main`
    * This merge will automatically create the next official major release in the `STABLE` channel.

The below Git workflow demonstrates this process, assuming that we start out with version `2.0.0` being the current stable release.

```mermaid
---
config:
  gitGraph:
    parallelCommits: true
---
gitGraph TB:
    commit id: "v2.0.0"
    branch pre-release
    branch next
    branch v3-feat-1
    branch next-4.x

    # v3 feature 1
    checkout v3-feat-1
    commit id: "feat: add v3 feature 1"
    checkout next
    merge v3-feat-1
    commit id: "Bump v3.0.0-beta.1"

    # v4 feature 1
    checkout next-4.x
    branch v4-feat-1
    commit id: "feat: add v4 feature 1"
    checkout next-4.x
    merge v4-feat-1
    commit id: "Bump v4.0.0-beta.1"

    # v3 feature 2 (Too busy when including this)
    #checkout next
    #branch v3-feat-2
    #commit id: "feat: add v3 feature 2"
    #checkout next
    #merge v3-feat-2
    #commit id: "Bump v3.0.0-beta.2"

    # Start Release Process
    checkout pre-release
    merge next id: "Release V3"
    commit id: "Bump v3.0.0-pre.1"
    checkout main
    merge pre-release
    commit id: "Bump v3.0.0"

    # Set up `next` for v4
    checkout next-4.x
    merge next id: "mergeback"
    checkout next
    merge next-4.x id: "v4.0.0-beta.2"

```

## Developing New Helm Chart Features
When developing new features or functionality for the Helm Chart, the chosen branching strategy depends on the following:

* Does the feature depend on a specific version of Smile CDR?
* Does the feature include breaking changes?
* Is there any urgency to officially release the feature before the next major Smile CDR release?
* Does the feature need to be back-ported to previous Helm Chart releases?

### Features Without Smile CDR Version Dependency
When developing a feature that does not depend on a specific future version of Smile CDR, the branching strategy will depend on whether the feature introduces a breaking change or not.

#### Without Breaking Changes
If the feature does **NOT** depend on a specific version of Smile CDR, and does **NOT** contain breaking changes, then it can be safely developed on the `pre-release` branch with the intent of inclusion as a minor version bump of the current stable major release.

#### With Breaking Changes
If the feature includes breaking changes, then it should be developed on the `next` branch with the intent of inclusion in the next major release, along with the next release of Smile CDR.

!!! note "Note on Urgent Features"
    In cases where there is urgency to have the new feature released ***before*** the next Smile CDR release cycle, we **SHOULD NOT** release a new major version of the Helm Chart, as it will throw off the predictable version mapping between Smile CDR versions and Helm Chart major versions.

    In such situations where the new functionality is critical for an environment, it may be preferable to use the next upcoming version of the Helm Chart before it is released. There are caveats with this approach, so it needs to be addressed on a case-by-case basis.

### Features With Smile CDR Version Dependency
If the feature or functionality depends on a specific future version of Smile CDR, then it should be developed on an appropriate `next` or `next-n.x` branch.

!!! note
    When creating a new `next-n.x` branch, ensure that its source branch has already incremented to version `n-1`. This is to ensure that the semantic release processes choose the correct version for the pre releases.

    For example: If you create a `next-3.x` branch, the source branch should already be on version `2.x.x` in order to ensure the pre releases will be version `3.x.x-pre.1`.

    See the [Post Release Tasks](#post-release-tasks) section for more info on updating `next` and `next-n.x` branches.

### Examples

The following examples assume that the current Helm Chart stable version is `1.1.1`, using Smile CDR `2024.05.R04`

=== "Without Smile CDR Version Dependency"

    === "Without Breaking Changes"

        If you are developing a new feature **WITHOUT** breaking changes.

        * You should use the `pre-release` branch to develop your feature.
        * This will result in pre release builds (e.g. `1.2.0-pre.1`) being released in the `DEVEL` channel to facilitate testing.
        * When you merge this change to `main`, version `1.2.0` will be released in the `STABLE` channel for general consumption.

    === "With Breaking Changes"

        If you are developing a new feature **WITH** breaking changes.

        * You should use the `next` branch to develop your feature.
        * This will result in pre release builds (e.g. `2.0.0-beta.1`) being released in the `DEVEL` channel to facilitate testing.
        * This feature will become part of version `2.0.0` when it is released to the `STABLE` channel for general consumption.

=== "With Smile CDR Version Dependency"

    If the new feature depends on a specific future Smile CDR version, then this is implicitly a breaking change. Therefore there is no option to use the `pre-release` branch, which is only to be used for non-breaking changes.

    If you are developing a feature that depends on Smile CDR `2024.11.x`

    * You should use the `next-3.x` branch to develop your feature.
    * This will result in a beta version (e.g. `3.0.0-beta.1`) being published in the `DEVEL` channel to facilitate testing.

## Developing Helm Chart Fixes
When developing hot-fixes or patch updates for the Helm Chart, the chosen branching strategy depends on the following:

* Is this an upstream patch change? (i.e. Changing the default Smile CDR version from `2024.05.R03` to `2024.05.R04`)
* Is this a Helm Chart fix/patch (i.e. a bug in the functioning of the Helm Chart)
* Does this fix affect all currently supported major versions of the Helm Chart?

### Helm Chart Fix/Patch
If your update is a fix for some broken Helm Chart functionality, and if it is **NOT** a breaking change, merge your changes to the `pre-release` branch if you want to preview the fix/patch on the `DEVEL` channel.
When ready to release the change, merge your changes to the `main` branch to release to the `STABLE` channel.

!!! note "Fixing Multiple Helm Chart Versions"

    If the fix is required on multiple versions of the Helm Chart, then the process will need to be repeated for the `release-n.x` branch for each of the currently supported releases.

### Upstream Smile CDR Patches
If you are simply updating the current Smile CDR release to the latest patch version, merge your changes to the `pre-release` branch if you want to preview the fix/patch on the `DEVEL` channel.
When ready to release the change, merge your changes to the `main` branch to release to the `STABLE` channel.

This process should only be performed on Helm Chart versions who's Smile CDR version has received a patch level update.

For example, if Smile CDR `2024.05.R04` gets updated to `2024.05.R05`, but `2024.08.R01` does not get updated, then changes would only be made to the version `1.x` release branch and not the `2.x` branch. When `2024.08.R01` gets updated to `2024.08.R02`, that change would only apply to the `2.x` branch.

### Merging Feature Branches
All updates should be developed on a feature branch. The feature branch should be created from the branch that you intent to contribute to.

All merges back to the appropriate release or pre release branch should be done using a Merge Request in GitLab. Release branches are protected and **SHOULD NOT** have commits pushed directly to them.

When creating feature branch merge requests, they should only be for a single feature. **DO NOT** include arbitrary changes in your feature branch, such as unrelated typos or formatting areas in different areas of code. These should be done in a separate branch/merge request.

You **MUST** squash your commits in your Merge Request and ensure that the commit follows the appropriate *conventional commits* message.

## Release workflow
For many of the above mentioned scenarios, there is the option to merge changes directly to a release branch (i.e. `main`, `release-1.x`, `release-2.x` etc ) or merge to a pre release branch first.

The approach to choose depends on the requirements for the feature.

### Merge to Pre Release Branches
Merge to branches that publish to the `DEVEL` channel when:

* The change is a breaking change for a future version of the Helm Chart.
* The change needs to be tested in test environments before being released to the `STABLE` channel.
* The change needs to be shared with others for testing purposes before being released to the `STABLE` channel.
* The change is only a partial implementation for a new feature that needs to be shared for collaborative purposes before it's completed.
* Successive iterations to a new feature may introduce breaking changes for that feature.
   * By adding consecutive breaking changes for a new feature in a pre release, you are still able to merge it to the `STABLE` branch when it's ready.
   * If you pushed the new feature early, and then made new changes that break that new feature, you would need to wait until the next major release to push them, which is not ideal.

### Merge to Release Branches
Merge to release branches when:

* The change is trivial, non-breaking and unlikely to need further work.
* In the event that a new feature is released as a minor version update, any breaking changes to the feature can wait until the next major version release.

### Promoting Pre Releases
Once you have published a change with a pre release version (on the `DEVEL` channel) you can promote it to the `STABLE` channel by creating a merge request from the pre release branch to the release branch.

For example, the branches would map as follows, assuming the current stable release is `2.0.0`

| Pre Release Version | Pre Release Branch | Release Version | Release Branch | Notes |
| - | - | - | - | - |
| `2.1.0-pre.1` | `pre-release` | `2.1.0` | `main` | `2.0.0` is the current stable release |
| `1.2.0-pre.1` | `pre-release-1.x` | `1.2.0` | `release-1.x` | This is a release on the 1.x maintenance branch |

### Promoting Beta Versions
When a beta version is ready to be released, you should promote it by creating a merge request from the `next` branch to the `pre-release` branch. From there, the above process is then used to promote it from the `DEVEL` release channel to `STABLE`

For example, the branches would map as follows, assuming the current stable major release is version `2.x` and you are about to release version `3.0.0`

| Beta Version | Beta Branch | Pre Release Version | Pre Release Branch | Notes |
| - | - | - | - | - |
| `3.0.0-beta.17` | `next`     | `3.0.0-pre.1`  | `pre-release` | When going from `next` to `pre-release` versioning starts with the `-pre.1` suffix |
| `4.0.0-beta.3`  | `next-4.x` | `4.0.0-beta.3` | `next` | Version number does not change |

## New Major Releases
Major version releases of the Smile CDR Helm Chart should coincide with new major releases of Smile CDR, i.e. when `2024.08.R01` is released, version `2.0.0` of the Helm Chart should be released.

Before releasing a new major version of the Helm Chart, there should already be development on the `next` branch. At the very least, there should be a breaking feature change on this branch to update to the new Smile CDR version.
!!! warning
    It is critical that there is at least 1 breaking change feature in this branch as Semantic Release requires this in order to automatically bump the major version

### Performing The Release
Promoting the `next` branch to `main` will release the next version, but there are other steps required to ensure that the above workflows function as expected afterwards.

All of the following steps should be performed by the repository maintainer.

* Ensure there are no outstanding changes to be merged from `pre-release` into `main`
* Ensure that `main` is fully merged back into `next` and tested, to capture any bug fixes that were created on the old main version.
* Create merge request to merge `next` into `pre-release`.
* Create merge request to merge `pre-release` into `main` to initiate the release process.
    * Commits **MUST NOT** be squashed as the pipeline relies on accurate *conventional commits* to determine the appropriate semantic version to apply.
    * The CI pipeline uses Semantic Release to test the build, increment the version, create the release, publish the Helm Chart and update the version in the branch (by committing back to the repo)

If we had just released version `3.0.0` using the above steps, the branches would now be in the following state:

| Branch | Current Version | Notes |
| - | - | - |
| `release-1.x` | `1.1.1` | Already created when version `2.0.0` was released. |
| `pre-release-1.x` | `1.1.1-pre.1` | Already created when version `2.0.0` was released. |
| `main` | `3.0.0` | Initial major release for version `3.x`. |
| `pre-release` | `3.0.0-pre.1` | This branch is now used for version `3.x` updates instead of `2.x`. |
| `next` | `3.0.0-beta.1` | This now needs to be updated for the `4.x` beta releases. |
| `next-v4` | `4.0.0-beta.1` | Branch for future version `4.x` beta releases. No longer required. |
| `next-v5` | `5.0.0-beta.1` | Branch for future version `5.x` beta releases. |


### Post-release Tasks
Note that after performing the release steps above, there are missing requirements:

* There are no maintenance or pre release branches for version `2.x`
* The `next` branch no longer represents the upcoming version `4.x`

These are addressed with the following post-release tasks that should be performed by the repository maintainer:

* Create a new maintenance branch for the previous version. **i.e.** If version `3.0.0` was just release to the `main` branch, then a new branch, `release-2.x` should be created to maintain the `2.x` releases.
* Create a new pre release branch for the previous release. **i.e.** Continuing from above, create a `pre-release-2.x` branch from the `release-2.x` branch
<!-- The deletion statement below to be confirmed -->
* Merge the `next-v4` branch into `next` so that it can be used for the next upcoming major release, version `4.0.0`. At this point, the `next-v4` branch is no longer required and may be deleted.
* Create the `next-v6` branch from the `next-v5` branch if the appropriate Pre-Release of Smile CDR is available.
