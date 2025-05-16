# Release Process Checklist
This checklist outlines the required steps for managing a new major release of the Smile CDR Helm Chart.

## 🔀 1. Start a New Major Release

### Prepare Release Branch
If the previous release has just been published, ensure that the `next-major` branch is ready for continuing development of the new release.

* Merge-back `main` into `next-major` - Currently performed by a repo maintainer after a release is published.

### Create Initial Feature Branch For New Release

As this process is normally initiated when preparing a new Helm Chart version for a future Smile CDR GA release, it's common for this inital branch to follow the format `add-support-for-smilecdr-yyyy-mm`. e.g. If creating the new release for Smile CDR `2025.05.*` you would do the following:

```
git checkout -b nnn-add-support-for-smilecdr-2025-05
```

### Update Version References

When starting a new Helm Chart version that defaults to a new version of Smile CDR, there are a few locations where the version information needs to be updated.

#### `src/main/charts/smilecdr/Chart.yaml`
Set `appVersion` to the appropriate Smile CDR version. e.g.
``` yaml
appVersion: "2025.05.PRE-RC13"
```
To find the appropriate version, refer to the Smile CDR releases website. e.g. [`2025.05` releases](https://releases.smilecdr.com/releases/2025/5/)

#### `src/main/charts/smilecdr/templates/scdr/_scdr-feature-gate.tpl`
Add appropriate entry in the `smilecdr.releases` template. This is used by the version checking and feature gating functionality of the Helm Chart. e.g.
``` go
{{- /* Smile CDR Version Matrix
     *
     */ -}}
{{- define "smilecdr.releases" -}}
  {{- $releases := dict
    "2025.05" (dict "name" "" "latest" "PRE-RC13") <-- Add this line to support `2025.05.PRE-RC-13` and above
    "2025.02" (dict "name" "" "latest" "R03")
    "2024.11" (dict "name" "" "latest" "R05")
    "2024.08" (dict "name" "" "latest" "R05")
    "2024.05" (dict "name" "" "latest" "R05")
    "2024.02" (dict "name" "" "latest" "R07")
  -}}
  {{- $releases | toYaml -}}
{{- end }}
```

### Update Documentation References

Although most of the versions displayed in the documentation are generated dynamically based on the most recent Git tag on the current branch, you do need to update the following:

#### `mkdocs.yml`
Add a new item in the Changelog section for the upcoming release. e.g.
``` yaml
...
      - 'Changelog':
        - "Version 5.x": charts/smilecdr/CHANGELOG-V5.md <-- Add this line to support v5 of the Helm Chart
        - "Version 4.x": charts/smilecdr/CHANGELOG-V4.md
        - "Version 3.x": charts/smilecdr/CHANGELOG-V3.md
        - "Version 2.x": charts/smilecdr/CHANGELOG-V2.md
        - "Version 1.x": charts/smilecdr/CHANGELOG-V1.md
```

>Note: You do NOT need to create the actual changelog file (e.g. `charts/smilecdr/CHANGELOG-V5.md`) as it will be created and updated by the automated release process.


#### `mkdocs/macros/main.py`
The current and past `stable` channel releases cannot be determined dynamically, so must be manually added in the `version_info` object MkDocs macro file.

<!-- >**Note:** This can either be updated when initially creating the new release, or in the final 'release preparation' branch (See below) -->

``` python
version_info = [
   {
      'chart_version': '5.0.0',
      'cdr_versions': {
            'default': '2025.05.R01',
            'max': '2025.05.*',
            'min': '2024.05.R01'
      }
   },
   # Existing entries below...
   ...
]
```
>**Note:** It's safe to use R01 for the default version here even if it's not yet released as it's only used for displaying stable channel releases in the documentation.

### Prepare Initial Commit For Release

Create the initial commit for the new release branch. It's important that this commit includes a breaking change so that the Semantic Versioning process bumps the major version.

* Update test outputs, review and stage changes:
   ```
   make helm-update-outputs
   ```

* Lint and run tests:
   ```
   make pre-commit
   ```
   If any files were updated (whitespace etc) then stage those changes

* Commit
   >**Note:** This should be a multi-line commit as follows!
   ```
   git commit -am "feat(smilecdr): add support for smilecdr yyyy-mm release

   This commit bumps the Helm Chart major version to vx.0.0

   Breaking Change: Updated Smile CDR from Version x to y"
   ```

* (Optional) Re-run pre-commit check:
   Re-running the commit check ensures that your commit message is formatted correctly.
   ```
   make pre-commit
   ```

* Push to origin (Your forked repository)

### Create Merge Request in Upstream Repository

Open an MR in GitLab:
- Source: `my-namespace/smile-dh-helm-charts:208-improve-developer-documentation`
- Target: `smilecdr-public/smile-dh-helm-charts:next-major`

After your Merge Request has been created, someone with the maintainer role will run the merge pipeline to verify that there are no regressions with the new code.
   - The merge request will be reviewed by an approved reviewer
   - The merge pipeline will be initiated by a repo maintainer
   - Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
   - The automatic release process will run, releasing a new version of the Helm Chart if required
   - The automatic documentation update process will run, updating the live documentation site
   - The `upstream/next-major` branch will now have the correct version for future feature branches.

## 📘 2. Update Code and Documentation

Follow the regular development process, creating feature branches from `upstream/next-major` to add features and update documentation for this upcoming version.

## ✅ 3. Perform Final Checks and Publish Release

Before publishing the new version, some final checks need to be made to ensure the release is ready.

<!-- ### Prepare Release Branch For Publishing
New Helm Chart versions are published into the `stable` channel by merging the `next-major` branch into the `main` branch.

Before doing this, some final checks need to be made to ensure the release is ready for publishing. -->

### Merge All Feature Branches
Before proceeding, ensure that all feature branches intended for this release have been merged into the `next-major` branch.

### Create Release Preparation Branch For Publishing Release
This will be the final '**feature branch**' created for this release where the final checks and updates can be made.

```
git checkout -b nnn-prepare-v5-release upstream/next-major
```

### Update Version References

Before publishing to the `stable` release channel, ensure no pre-release versions remain in the code.

#### `src/main/charts/smilecdr/Chart.yaml`
Update `appVersion` to the appropriate Smile CDR version. Ensure it is no longer pointing to a pre-release version of Smile CDR.

``` yaml
appVersion: "2025.05.R01"
```
If the release of the Helm Chart is not delayed, this will typically be the `R01` patch version of the GA release.

#### `src/main/charts/smilecdr/templates/scdr/_scdr-feature-gate.tpl`
Update the entry in the `smilecdr.releases` template that was created for this release.
``` go
{{- /* Smile CDR Version Matrix
     *
     */ -}}
{{- define "smilecdr.releases" -}}
  {{- $releases := dict
    "2025.05" (dict "name" "" "latest" "R01") <-- Add this line to support `2025.05.R01` and above
    "2025.02" (dict "name" "" "latest" "R03")
    "2024.11" (dict "name" "" "latest" "R05")
    "2024.08" (dict "name" "" "latest" "R05")
    "2024.05" (dict "name" "" "latest" "R05")
    "2024.02" (dict "name" "" "latest" "R07")
  -}}
  {{- $releases | toYaml -}}
{{- end }}
```

### Update Documentation References

#### `mkdocs.yml`
Confirm that the appropriate Changelog section was already added.
``` yaml
...
      - 'Changelog':
        - "Version 5.x": charts/smilecdr/CHANGELOG-V5.md <-- Confirm that this was already present
        - "Version 4.x": charts/smilecdr/CHANGELOG-V4.md
        - "Version 3.x": charts/smilecdr/CHANGELOG-V3.md
        - "Version 2.x": charts/smilecdr/CHANGELOG-V2.md
        - "Version 1.x": charts/smilecdr/CHANGELOG-V1.md
```

#### `mkdocs/macros/main.py`
If this was not updated when initially creating the new release, it should be updated now.

``` python
version_info = [
   {
      'chart_version': '5.0.0',
      'cdr_versions': {
            'default': '2025.05.R01',
            'max': '2025.05.*',
            'min': '2024.05.R01'
      }
   },
   # Existing entries below...
   ...
]
```

#### Update Migration Guide
**Source**: `docs/upgrading/index.md`

A new item should be created under the 'Migration Guides' section that covers any steps required for migrating to this version of the Helm Chart.

Copy an existing section as a guideline. It should include the following:

```
### `v4.x` to `v5.x`

This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v4.x` to `v5.x`.

---

#### Overview of Changes
- Default Smile CDR version updated from `2025.02.xx` to `2025.05.R01`.
- Feature 1
- Fearure 2

##### Feature 1 (Informational)
< Brief info about feature 1 >

##### Feature 2 (Informational)
< Brief info about feature 2 >

---

### Actionable Items
Review the following action items to address any potentially breaking changes.

!!! warning
    **REMINDER! - [Pin Your Smile CDR Version](#pin-your-smile-cdr-version)<br>**
    As a reminder, always [Pin Your Smile CDR Version](#pin-your-smile-cdr-version) when upgrading the Helm Chart, in order to prevent unexpected changes to your Smile CDR release.

##### Breaking Change 1
< Add information about potentially breaking change >
< Include any instructuons that should be followed because of this change >

```

### Check Smile CDR Release for Filesystem Changes
There are certain files that the Helm Chart generates dynamically rather than using the defaults that are included with Smile CDR packages.

If these files are changed in a new Smile CDR release, then the Helm Chart should be updated to reflect these changes before publishing to the `stable` release channel.

Visit the [Smile CDR Releases Site](https://releases.smilecdr.com/) and download the version of Smile CDR being referenced in this Helm Chart version in order to perform the following checks:

* Download the `tar` archive of the Smile CDR release
* Extract the archive
* Open the default properties file: `classes/cdr-config-Master.properties`.
* Compare configurations with the default module configuration in `src/main/charts/smilecdr/default-modules.yaml`
  >Note: This is currently a laborious manual process. Tooling is under development to simplify this process.
* Open the `smileutil` file: `bin/smileutil`.
* Compare with the `smileutil` file from the previous release.
  If differences are found, seek collaboration to see if any updates should be made.

### Prepare Final Commit For Release

Create the final commit for the release. Note that unlike the initial commit for this release, the final release does NOT need to include a breaking change. Doing so will clutter the release notes with duplicate breaking changes.

* Update test outputs, review and stage changes:
   ```
   make helm-update-outputs
   ```

* Lint and run tests:
   ```
   make pre-commit
   ```
   If any files were updated (whitespace etc) then stage those changes

* Commit
   >**Note:** This should be a multi-line commit as follows!
   ```
   git commit -am "chore(smilecdr): prepare release for v5.0

   This commit finalizes changes for releasing the Smile CDR Helm Chart v5.0.0"
   ```

* (Optional) Re-run pre-commit check:
   Re-running the commit check ensures that your commit message is formatted correctly.
   ```
   make pre-commit
   ```

* Push to origin (Your forked repository)

### Create Merge Request in Upstream Repository

Open an MR in GitLab:
- Source: `my-namespace/smile-dh-helm-charts:nnn-prepare-v5-release`
- Target: `smilecdr-public/smile-dh-helm-charts:next-major`

After your Merge Request has been created, someone with the maintainer role will run the merge pipeline to verify that there are no regressions with the new code.
   - The merge request will be reviewed by an approved reviewer
   - The merge pipeline will be initiated by a repo maintainer
   - Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
   - The automatic release process will run, releasing a new version of the Helm Chart if required
   - The automatic documentation update process will run, updating the live documentation site
   - The `upstream/next-major` branch will now have the correct version for future feature branches.

### Create Merge Request to `main` Branch

>Note: This step will be performed by a repository maintainer when we are ready to publish the release

Open an MR in GitLab:
- Source: `smilecdr-public/smile-dh-helm-charts:next-major`
- Target: `smilecdr-public/smile-dh-helm-charts:main`

After the Merge Request is created, the merge pipeline will automatically run to verify that there are no regressions with the new code.
   - Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
   - The automatic release process will run, releasing the new major version of the Helm Chart
   - The automatic documentation update process will run, updating the 'latest' documentation site
   - The `upstream/main` branch will now reflect the new Helm Chart version.

### Mergeback `main` to `next-major`

>Note: This step will be performed by a repository maintainer after the release has been published

The automated release process will create a new commit on the `main` branch, which means that it will now be ***ahead*** of `next-major`. To fix this, `main` needs to be merged into `next-major` before work can proceed on the next upcoming major release of the Helm Chart.
