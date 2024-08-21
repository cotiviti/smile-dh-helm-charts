# Branching Strategy and Versioning Workflow for Smile CDR Helm Charts

## Overview

This document outlines the branching strategy and versioning workflow for the Smile CDR Helm Charts.

The workflow is based on the semantic-release [workflow](https://semantic-release.gitbook.io/semantic-release/recipes/release-workflow) but has been modified to work in conjunction with the Smile CDR release process.

This branching strategy aligns with Semantic Release guidelines and integrates with the CI pipeline for automated versioning and release management.

### Branching Strategy

We use the following branches:

| Branch | Release Channel | Usage |
| - | - | - |
| **`main`** | `STABLE` | Contains the latest stable, production-ready release |
| **`pre-release`** | `DEVEL` | Used for developing non-breaking changes on the current major Helm Chart version |
| **`next`** | `DEVEL` | Used for ongoing development of the next major version |
| **`next-n.x`** | `DEVEL` | Used for developing and previewing releases beyond the next version |
| **`release-n.x`** | `STABLE` | Used for maintaining stable updates for the `n.x` versions. Created after the release of the next version |
| **`pre-release-n.x`** | `DEVEL` | Used for previewing maintenance updates for the `release-n.x` branches. |
| **`my-feature-1`** | NA | Create feature branches to develop your features. No releases or pre-releases get created |

<!-- Alternative was messy...
* **`main`**: Contains the latest stable, production-ready release.
* **`pre-release`**: Used for developing non-breaking changes on the current major Helm Chart version
* **`next`**: The canonical branch for ongoing development of the next major version.
    * e.g. If the current stable release is version `2.0.0`, then `next` will be used for development previews for version `3.0.0`.
* **`next-n.x`** or **`pre-release-n.x`** (TBD): Used for developing and previewing releases beyond the next version.
    * e.g. `next-4.x` or `pre-release-4.x` will be used for development previews for version `4.0.0` while the current stable release is version `2.x.x`.
* **`release-n.x`**: Used for maintaining stable updates for the `n.x` versions. Created after the release of the next version.
    * e.g. `release-2.x` will be used for patch/minor updates for version `2.x` and is created upon the release of version `3.0.0`. -->

### Branch Flow for Release and Maintenance Branches

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

<!-- checkout next
    branch v2-feat-1
    commit id: "feat: add v2 feature 1"
    checkout next
    merge v2-feat-1
    commit id: "Bump v2.0.0-pre.1"
    branch v2-feat-2
    commit id: "feat: add v2 feature 2"
    checkout next
    merge v2-feat-2
    commit id: "Bump v2.0.0-pre.2"
    
    checkout pre-release
    merge next
    commit id: "Bump v2.0.0-pre.3"
    checkout main
    branch release-1.x
    checkout main
    merge pre-release id: "v2.0.0"

    checkout pre-release
    branch v2-feat-3
    commit id: "feat: add v2 feature 3"
    checkout pre-release
    merge v2-feat-3
    commit id: "Bump v2.1.0-pre.1"
    checkout main
    merge pre-release
    commit id: "Bump v2.1.0"

    checkout next
    branch v3-feat-1
    commit id: "feat: add v3 feature 1"
    checkout next
    merge v3-feat-1
    commit id: "Bump v3.0.0-pre.1"

    #checkout release-1.x
    #branch v1-fix-1
    #commit id: "fix: fix v1"
    #checkout release-1.x
    #merge v1-fix-1 id: "v1.1.1" -->
    


<!-- ```mermaid
---
config:
  gitGraph:
    parallelCommits: true
---
gitGraph TB:
    checkout main
    commit id: "v1.0.0"
    branch pre-release
    branch v1-feat-1
    branch release-1.x
    branch hotfix-1
    branch next
    checkout hotfix-1
    commit id: "fix: fix v1"
    checkout release-1.x
    merge hotfix-1
    checkout next
    branch v2-feat-1
    commit id: "feat: add v2 feature"
    checkout next
    merge v2-feat-1
    checkout v1-feat-1
    commit id: "feat: add v1 feature"
    checkout pre-release
    merge v1-feat-1
    checkout main
    merge pre-release id: "v1.1.0"
``` -->


<!-- ```mermaid
gitGraph TB:
    commit id: "v1.0.0"
    branch pre-release
    checkout pre-release
    branch patch
    checkout patch
    commit id: "fix"
    checkout pre-release
    merge patch
    checkout main
    merge pre-release
    commit id: "v1.0.1"
    checkout pre-release
    merge main
    branch feat
    checkout feat
    commit id: "feature"
    checkout pre-release
    merge feat
    checkout main
    merge pre-release
    commit id: "v1.1.0"

``` -->

### Versioning

- **Major Releases**: Occur every 3 months, aligned with the upstream releases of Smile CDR. For example, version `1.x` corresponds to Smile CDR `2024.05.x`, and version `2.x` to `2024.08.x`.
- **Minor Releases**: Occur whenever new non-breaking changes are released. Typically these are only released on the current production version. Back-porting of features to previous versions of the Helm Chart will be considered on an individual basis. It is always recommended to upgrade to the current stable Helm Chart version rather than back-porting to a previous version.
- **Patch Releases**: Occur in the following scenarios:
    * To align with patch level updates of Smile CDR. For example, by default, version `1.1.0` of the Helm Chart uses Smile CDR `2024.05.R03`, and version `1.1.1` uses `2024.05.R04`. These patch updates will only apply to the current stable version of the Helm Chart
    * Critical bug or security fixes to the Helm Chart. These bug fixes will be back-ported to the previous 4 major versions of the Helm Chart if it is technically feasible to do so.
- **Pre-releases**: Named in the format `X.Y.Z-pre.n`, where `X.Y.Z` represents the version being previewed, and `n` is the pre-release number.
    * Incremental pre-releases before a major version update (e.g. upgrading from version `3.0.0-pre.5` to version `3.0.0-pre.6`) may include breaking changes.
    * After `3.0.0` is released, the following `3.x` pre-releases will not contain breaking changes.


## Developing New Helm Chart Features
When developing new features or functionality for the Helm Chart, the chosen branching strategy depends on the following:

* Does the feature depend on a specific version of Smile CDR?
* Does the feature include breaking changes?
* Is there any urgency to officially release the feature before the next major Smile CDR release?
* Does the feature need to be back-ported to previous Helm Chart releases?

### Features Without Smile CDR Version Dependency
When developing a feature that does not depend on a specific future version of Smile CDR, the branching strategy will depend on whether the feature introduces a breaking change or not.

#### Without Breaking Changes
If the feature does **NOT** depend on a specific version of Smile CDR, and does **NOT** contain breaking changes, then it can be safely developed on the **`pre-release`** branch with the intent of inclusion as a Minor version bump of the current stable release.

#### With Breaking Changes
If the feature includes breaking changes, then it should be developed on the **`next`** branch with the intent of inclusion in the next Major release, along with the next release of Smile CDR.

!!! note "Note on Urgent Features"
    In cases where there is urgency to have the new feature released ***before*** the next Smile CDR release cycle, we **SHOULD NOT** release a new major version of the Helm Chart, as it will throw off the predictable version mapping between Smile CDR versions and Helm Chart major versions.

    In such situations where the new functionality is critical for an environment, it may be preferable to use the next upcoming version of the Helm Chart before it is released. There are caveats with this approach, so it needs to be addressed on a case-by-case basis.

### Features With Smile CDR Version Dependency
If the feature or functionality depends on a specific future version of Smile CDR, then it should be developed on an appropriate `pre-release-n.x` branch.

!!! note
    When creating a new `pre-release-n.x` branch, ensure that its source branch has already incremented to version `n-1`. This is to ensure that the semantic release processes choose the correct version for the pre-releases.

    For example: If you create a `pre-release-3.x` branch, the source branch should already be on version `2.x.x` in order to ensure the pre-releases will be version `3.x.x-pre.1`.3

    See the [Pre Release]() section below.code

### Features Without Breaking Changes
If the feature does **NOT** depend on a specific version of Smile CDR, then it should be developed on the `pre-release` branch with the intent of inclusion as a minor version in the current release.

### Examples

The following examples assume that the current Helm Chart stable version is `1.1.1`, using Smile CDR `2024.05.R04`

=== "Without Smile CDR Version Dependency"

    === "Without Breaking Changes"

        If you are developing a new feature **WITHOUT** breaking changes.
        
        * You should use the `pre-release` branch to develop your feature.
        * This will result in pre-release builds (e.g. `1.2.0-pre.1`) being released in the `DEVEL` channel to facilitate testing.
        * When you merge this change to `main`, version `1.2.0` will be released in the `STABLE` channel for general consumption.

    === "With Breaking Changes"

        If you are developing a new feature **WITH** breaking changes.
        
        * You should use the `next` branch to develop your feature.
        * This will result in pre-release builds (e.g. `2.0.0-pre.1`) being released in the `DEVEL` channel to facilitate testing.
        * This feature will become part of version `2.0.0` when it is released to the `STABLE` channel for general consumption.

=== "With Smile CDR Version Dependency"

    If the new feature depends on a specific future Smile CDR version, then this is implicitly a breaking change. Therefore there is no option to use the `pre-release` branch, as it is only to be used for non-breaking changes.

    If you are developing a feature that depends on Smile CDR `2024.11.x`

    * You should use the `pre-release-3.x` branch to develop your feature.
    * This will result in pre-release builds (e.g. `3.0.0-pre.1`) being published in the `DEVEL` channel to facilitate testing.


<!-- ### Examples 2

=== "Without Breaking Changes"
    
    === "Without Smile CDR Version Dependency"

        If you are developing a new feature with no breaking changes or Smile CDR Version Dependencies.
        
        * You should use the `pre-release` branch to develop your feature.
        * This will result in pre-release builds (e.g. `1.2.0-pre.1`) being released in the `DEVEL` channel to facilitate testing.
        * When you merge this change to `main`, version `1.2.0` will be released in the `STABLE` channel for general consumption.

    === "With Smile CDR Version Dependency"
    
        If you are developing a feature that depends on Smile CDR `2024.11.x`

        * You should use the `pre-release-3.x` branch to develop your feature.
        * This will result in pre-release builds (e.g. `3.0.0-pre.1`) being published in the `DEVEL` channel to facilitate testing.
        * This approach should not be affected by breaking changes as the upgrade to the next version of Smile CDR already implicitly includes a breaking change.

=== "With Breaking Changes"

    If you are developing a new feature **WITH** breaking changes.
        
    * You should use the `pre-release` branch to develop your feature.
    * This will result in pre-release builds (e.g. `1.2.0-pre.1`) being released in the `DEVEL` channel to facilitate testing.
    * When you merge this change to `main`, version `1.2.0` will be released in the `STABLE` channel for general consumption. -->

## Developing Helm Chart Fixes
When developing hot-fixes or patch updates for the Helm Chart, the chosen branching strategy depends on the following:

* Is this an upstream patch change? (i.e. Changing the default Smile CDR version from `2024.05.R03` to `2024.05.R04`)
* Is this a Helm Chart fix/patch (i.e. a bug in the functioning of the Helm Chart)
* Does this fix affect all currently supported Major versions of the Helm Chart?

### Helm Chart Fix/Patch
If your update is a fix for some broken Helm Chart functionality, and if it is NOT a breaking change, merge your changes to the `pre-release` branch if you want to preview the fix/patch on the `DEVEL` channel.
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

All merges back to the appropriate release or pre-release branch should be done using a Merge Request in GitLab. Release branches are protected and **SHOULD NOT** have commits pushed directly to them.

When creating feature branch merge requests, they should only be for a single feature. **DO NOT** include arbitrary changes in your feature branch, such as unrelated typos or formatting areas in different areas of code. These should be done in a separate branch/merge request.

You **MUST** squash your commits in your Merge Request and ensure that the commit follows the appropriate *conventional commits* message.

## Release workflow
For many of the above mentioned scenarios, there is the option to merge changes directly to a release branch (i.e. `main`, `release-1.x`, `release-2.x` etc ) or merge to a pre-release branch first.

The approach to choose depends on the requirements for the feature.

### Merge to Pre-Release Branches
Merge to pre-release branches (`DEVEL` Channel) when:

* The change is a breaking change for a future version of the Helm Chart.
* The change needs to be tested in test environments before being released to the `STABLE` channel.
* The change needs to be shared with others for testing purposes before being released to the `STABLE` channel.
* The change is only a partial implementation for a new feature that needs to be shared for collaborative purposes before it's completed.
* Successive iterations to a new feature may introduce breaking changes for that feature.
   * By adding consecutive breaking changes for a new feature in a pre-release, you are still able to merge it to the `STABLE` branch when it's ready.
   * If you pushed the new feature early, and then made new changes that break that new feature, you would need to wait until the next Major release to push them, which is not ideal.

### Merge to Release Branches
Merge to release branches (`STABLE` Channel) when:

* The change is a trivial, non-breaking and unlikely to need further work.
* In the event that a new feature is released as a Minor version update, any breaking changes to the feature can wait until the next Major version release.

### Promoting pre-releases
Once you have published a change with a pre-release version (on the `DEVEL` channel) you can promote it to the `STABLE` channel by creating a merge request from the pre-release branch to the release branch.

For example, the branches would map as follows, assuming the current stable release is `2.0.0`

| Pre-release Version | Pre-release Branch | Release Version | Release Branch | Notes |
| - | - | - | - | - |
| `1.2.0-pre.1` | `pre-release-1.x` | `1.2.0` | `release-1.x` | This is a release on the 1.x maintenance branch |
| `2.1.0-pre.1` | `pre-release` | `2.1.0` | `main` | `2.0.0` is the current stable release |
| `3.0.0-pre.1` | `next` | N/A | N/A | No maintenance release branch created until version `3.0.0` is released |
| `4.0.0-pre.1` | `next-4.x` | N/A | N/A | No maintenance release branch created until version `4.0.0` is released |

## New Major Releases
Major version releases of the Smile CDR Helm Chart should coincide with new Major releases of Smile CDR, i.e. when `2024.08.R01` is released, version `2.0.0` of the Helm Chart should be released.

Before releasing a new major version of the Helm Chart, there should already be development on the `next` branch. At the very least, there should be a breaking feature change on this branch to update to the new Smile CDR version.

### Performing The Release
Performing a merge request from `next` to `main` <!-- (via `pre-release` if alternative method below is used) -->is sufficient to release the next version, but there are other steps required to ensure that the above workflows function as expected. All of the following steps should be performed by the repository maintainer.

<!-- Not needed if alternative method below is used -->
* Ensure there are no outstanding changes to be merged from `pre-release` into `main`
* Ensure that `main` is fully merged back into `next` and tested, to capture any bug fixes that were created on the old main version.
* Creates merge request to merge `next` into `main` to initiate the release process.
<!-- Alternative:
* Creates merge request to merge `next` into `pre-release`.
* Creates merge request to merge `pre-release` into `main` to initiate the release process. -->
* After the CI pipelines have succeeded, complete the merge request.
    * Commits **MUST NOT** be squashed as the pipeline relies on accurate *conventional commits* to determine the appropriate semantic version to apply.
    * The CI pipeline uses Semantic Release to test the build, increment the version, create the release, publish the Helm Chart and update the version in the branch (by committing back to the repo)

If we just released version `3.0.0`, the branches would now be in the following state:

| Branch | Current Version | Notes |
| - | - | - |
| `release-1.x` | `1.1.1` | Created when version `2.0.0` was released |
| `pre-release-1.x` | `1.1.1-pre.1` | |
| `main` | `3.0.0` | Initial release for version `3.x` |
| `pre-release` | `3.0.0-pre.1` | New pre-release branch for version `3.x` updates |
| `next` | `3.0.0-pre.1` | This needs to be updated for the new `next` release |
| `next-v4` | `4.0.0-pre.1` | Pre-release branch for future version `4.x` release |
| `next-v5` | `5.0.0-pre.1` | Pre-release branch for future version `5.x` release |

<!-- Alternative - the Minor/Major versions may have been a little much for this table...
| Branch | Current Version | Next Minor Version | Next Major Version | Notes |
| - | - | - | - | - |
| `release-1.x` | `1.1.1` | `1.1.2` | `1.2.0` | Created when version `2.0.0` was released |
| `pre-release-1.x` | `1.1.1-pre.1` | `1.1.2-pre.1` | `1.2.0-pre.1` | |
| `main` | `3.0.0` | `3.0.1` | `3.1.0` | Initial release for version `3.x` |
| `pre-release` | `3.0.0-pre.1` | `3.0.1-pre.1` | `3.1.0-pre.1` | New pre-release branch for version `3.x` updates |
| `next` | `3.0.0-pre.1` | `3.0.0-pre.2` | `3.0.0-pre.2` | This needs to be updated for the new `next` release |
| `next-v4` | `4.0.0-pre.1` | `4.0.0-pre.1` | `4.0.0-pre.1` | Old pre-release branch for the upcoming version `4.x` release |
| `next-v5` | `5.0.0-pre.1` | `5.0.0-pre.1` | `5.0.0-pre.1` | Old pre-release branch for the upcoming version `5.x` release | -->

### Post-release Tasks
Note that after performing the release steps above, there are missing requirements:

* There are no maintenance or pre-release branches for version `2.x`
* The `next` branch no longer represents the upcoming version `4.x`

These are addressed with the following post-release tasks that should be performed by the repository maintainer:

* Create a new maintenance branch for the previous version. i.e. If version `3.0.0` was just release to the `main` branch, then a new branch, `release-2.x` should be created to maintain the `2.x` releases.
* Create a new pre-release branch for the previous release. i.e Continuing from above, create a `pre-release-2.x` branch from the `release-2.x` branch
* Merge the `next-v4` branch into `next` so that it can be used for the next upcoming Major release, version `4.0.0`. At this point, the `next-v4` branch is no longer required and may be deleted (to be confirmed).
* Create the `next-v6` branch from the `next-v5` branch if the appropriate pre-release of Smile CDR is available.
