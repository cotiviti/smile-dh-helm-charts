In order to reliably release new versions of the Helm Chart, the following release process has been defined.

## Release workflow
For many of the above mentioned scenarios, there is the option to merge changes directly to a release branch (i.e. `main`, `release-1.x`, `release-2.x` etc ) or merge to a pre release branch first.

The approach to choose depends on the requirements for the feature.

### Merge to Pre Release Branches
Merge to branches that publish to one of the pre release channels when:

* The change is a breaking change for a future version of the Helm Chart.
* The change needs to be tested in test environments before being released to the `stable` channel.
* The change needs to be shared with others for testing purposes before being released to the `stable` channel.
* The change is only a partial implementation for a new feature that needs to be shared for collaborative purposes before it's completed.
* Successive iterations to a new feature may introduce breaking changes for that feature.
   * By adding consecutive breaking changes for a new feature in a pre release, you are still able to merge it to the `stable` branch with a single release when it's ready.
   * If you pushed the new feature early, and then made new changes that break that new feature, you would need to wait until the next major release to push them, which is not ideal.

### Merge to Release Branches
Merge to release branches when:

* The change is trivial, non-breaking and unlikely to need further work.
* In the event that a new feature is released as a minor version update, any required breaking changes to the new feature **MUST** wait until the next major version release.

### Promoting Pre Releases
Once you have published a change to the `pre-release` channel, you can promote it to the `stable` channel by creating a merge request from the `pre-release` branch to the `main` branch.

For example, the branches would map as follows, assuming the current stable release is `2.0.0`

| Pre Release Version | Pre Release Branch | Release Version | Release Branch | Notes |
| - | - | - | - | - |
| `2.1.0-pre.1` | `pre-release` | `2.1.0` | `main` | `2.0.0` is the current stable release |

### Promoting Major Releases
When an upcoming major version is ready to be released, you should promote it by creating a merge request from the `next-major` branch to the `pre-release` branch. From there, the above process is then used to promote it from there to the `stable` release channel.

For example, the branches would map as follows, assuming the current stable major release is version `2.x` and you are about to release version `3.0.0`

| Next Major Version | Branch | Pre Release Version | Pre Release Branch | Notes |
| - | - | - | - | - |
| `3.0.0-next-major.17` | `next-major`     | `3.0.0-pre.1`  | `pre-release` | When going from `next-major` to `pre-release` versioning restarts with the `-pre.1` suffix |
| `4.0.0-beta.3`  | `beta` | `4.0.0-next-major.1` | `next-major` | When going from `beta` to `next-major` versioning restarts with the `-next-major.1` suffix |

## New Major Releases
Major version releases of the Smile CDR Helm Chart are aligned with the quarterly releases of Smile CDR, i.e. when `2024.08.R01` is released, version `2.0.0` of the Helm Chart should be released.

Before releasing a new major version of the Helm Chart, there should already be development on the `next-major` branch. At the very least, there should be a breaking feature change on this branch to update to the new Smile CDR version.
!!! warning
    It is critical that there is at least 1 breaking change feature in this branch as Semantic Release requires this in order to automatically bump the major version

### Performing The Release
Promoting the `pre-release` branch to `main` will release the next version, but there are other steps required to ensure that the above workflows function as expected afterwards.

All of the following steps should be performed by the repository maintainer.

* Ensure there are no outstanding changes to be merged from `pre-release` into `main`
* Ensure that `main` is fully merged back into the `pre-release` and `next-major` branches. Any changes need to be tested, to capture any bug fixes that were created on the old main version.
* Create merge request to merge `next-major` into `pre-release`.
* Create merge request to merge `pre-release` into `main` to initiate the release process.
    * Commits **MUST NOT** be squashed when promoting release channels, as the pipeline relies on accurate *conventional commits* to determine the appropriate semantic version to apply.
    * The CI pipeline uses Semantic Release to test the build, increment the version, create the release, publish the Helm Chart and update the changelog (by committing it back to the repo) and update the documentation.

If we had just released version `3.0.0` using the above steps, the branches would now be in the following state:

| Branch | Current Version | Notes |
| - | - | - |
| `release-1.x` | `1.1.1` | Already created when version `2.0.0` was released. |
| `main` | `3.0.0` | Initial major release for version `3.x`. |
| `pre-release` | `3.0.0-pre.1` | This branch is now used for version `3.x` updates instead of `2.x`. |
| `next-major` | `3.0.0-next-major.1` | This now needs to be updated for the `4.x` beta releases. |

### Post-release Tasks
Note that after performing the release steps above, there are missing requirements:

* There are no maintenance branches for version `2.x` releases
* The `next-major` branch does not yet represent the upcoming version `4.x` release

These are addressed with the following post-release tasks that should be performed by the repository maintainer:

* Create a new maintenance branch for the previous version. **i.e.** If version `3.0.0` was just release to the `main` branch, then a new branch, `release-2.x` should be created to maintain the `2.x` releases.
* If it exists, merge the `beta` branch into `next-major` so that it can be used for the next upcoming major release, version `4.0.0`.
