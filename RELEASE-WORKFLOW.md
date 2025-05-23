# Release Process Checklist
This checklist outlines the required steps for managing a new major release of the Smile CDR Helm Chart.

## 🔀 1. Start a New Major Release

### Prepare Release Branch
If the previous release has just been published, ensure that the `next-major` branch is ready for continuing development of the new release.

* Merge-back `main` into `next-major` - Currently performed by a repo maintainer after a release is published.

### Create GitLab Issue for New Release

The major release creation process should be started by creating a new GitLab issue with the following details
* Create Issue: Go [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/new) to create the new issue.
* Title:
  ```
  Smile CDR - Add support for Smile CDR YYYY.MM GA release
  ```
* Description:
  ```
  Add support for upcoming Smile CDR YYYY.MM quarterly GA release.
  This change should bump the Helm Chart version from vx to v9
  ```
* Labels:
   * SmileCDR
* Milestone:
   Select the milestone `Version x (YYYY.MM) Release. Create the milestone if it does not already exist.

### Create Feature Branch For New Release

The release branch should be created from the `upstream/next-major` branch and should follow the format `NNN-add-support-for-smile-cdr-YYYY-MM-ga-release`, where `NNN` is the GitLab issue created above and `YYYY-MM` id the next Smile CDR quarterly release.

e.g. If the issue number was `123` and you are creating the new release for the Smile CDR `2025.05` quarterly release, you would do the following:

```
git checkout -b 123-add-support-for-smile-cdr-2025-05-ga-release upstream/next-major
```

### Update Version References

When starting a new Helm Chart release, the referenced Smile CDR quarterly release needs to be updated.

There are a few locations where this information needs to be updated.

#### Update Helm Chart Definition
Location: `src/main/charts/smilecdr/Chart.yaml`

Set `appVersion` to the latest available version for the given Smile CDR quarterly GA release. e.g.
``` yaml
appVersion: "2025.05.PRE-RC13"
```
Always use the latest currently available version for the Smile CDR quarterly release.

Refer to the Smile CDR releases website to find this information. e.g. Published `2025.05` releases can be found [here](https://releases.smilecdr.com/releases/2025/5/).

>**Warning!**: Do **NOT** use a future version that is not yet published. Doing so will cause the Helm Chart to fail during deployment.

#### Update Feature Gates
Location:  `src/main/charts/smilecdr/templates/scdr/_scdr-feature-gate.tpl`

Add an appropriate entry in the `smilecdr.releases` template. This is used by the version checking and feature gating functionality of the Helm Chart.

Use the same version that was used in `appVersion` above.

e.g.
``` go
{{- /* Smile CDR Version Matrix
     *
     */ -}}
{{- define "smilecdr.releases" -}}
  {{- $releases := dict
    "2025.05" (dict "name" "Fortification" "latest" "PRE-RC13") <-- Add this line to support `2025.05.PRE-RC-13` and above
    "2025.02" (dict "name" "Transfiguration" "latest" "R03")
    "2024.11" (dict "name" "Despina" "latest" "R05")
    "2024.08" (dict "name" "Copernicus" "latest" "R05")
    "2024.05" (dict "name" "Borealis" "latest" "R05")
    "2024.02" (dict "name" "Apollo" "latest" "R07")
  -}}
  {{- $releases | toYaml -}}
{{- end }}
```

### Update Documentation References

Most of the versions displayed in the documentation are generated dynamically based on the most recent Git tag on the current branch.

However, you do need to update the following:

#### Add Migration Guide
Location: `docs/upgrading/index.md`

A new item should be created under the 'Migration Guides' section that covers any steps required for migrating to this version of the Helm Chart.

Copy an existing section, or use the following markdown as a guideline:

   ```
      ### `v4.x` to `v5.x`

      This section outlines key changes and required actions when upgrading from Smile CDR Helm Chart version `v4.x` to `v5.x`.

      ---

      #### Overview of Changes
      - Default Smile CDR GA release updated from `YYYY.MM` to `YYYY.MM`.

      ---

      #### Actionable Items
      ##### Check Helm Chart Warnings

      Before any upgrade, check the output of your `helm install` command for any warnings.

      These warnings may include misconfigurations or deprecation warnings that may affect your upgrade.

      ??? note "Displaying Helm Chart warnings when deploying with Terraform"
         If deploying using the Terraform `helm_release` resource, you may not see the warnings during deployment as they are not displayed by default.

         In order to check the warnings, you can get the Helm release notes directly like so:
         ```
         helm -n my-namespace list # <- to get list of releases
         helm -n my-namespace get notes <release-name>
         ```

      If you see the following output, it is safe to upgrade the Helm Chart
      ```
      ***************************
      **** NO CHART WARNINGS ****
      ***************************
      ```

      ##### Pin Your Smile CDR Version
      **ALWAYS Pin Your Smile CDR Version!**

      As a reminder, always [Pin Your Smile CDR Version](#pin-your-smile-cdr-version) when upgrading the Helm Chart, in order to prevent unexpected changes to your Smile CDR release.

      !!! warning
         Failure to pin your Smile CDR version ***will*** result in unexpected upgrades to the version of Smile CDR being deployed.

      ##### Upgrade-related Changes
      Review the following action items to address any potentially breaking changes.

      No additional changes are required to upgrade from v4.x to v5.0
   ```

>Note: This documentation should be updated as features are added, if they require upgrade actions.

#### Add Changelog Link
Location: `mkdocs.yml`

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

>Note: You do **NOT** need to create the actual changelog file (e.g. `charts/smilecdr/CHANGELOG-V5.md`) as it will be created and updated by the automated release process.

#### Update MkDocs Version Macro
Location: `mkdocs/macros/main.py`

The current and past `stable` channel releases cannot be determined dynamically by the included MkDocs macros. They must be hard coded manually by adding them to the `version_info` object.

Even if the Smile CDR GA release has not already been published, you should still use `R01` for the default version. This information is only used for displaying stable channel releases in the documentation.

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

### Prepare Initial Commit For Release

Create the initial commit for the new release branch. The format and contents of this commit need to be correct in order for the automated release process to function correctly.

It must contain a suitable message that will be visible as the first feature in this release and it must be a 'Breaking Change' so that the automated release process bumps the Helm Chart major version.


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
   git commit -am "feat(smilecdr): Add support for Smile CDR `YYYY.MM` GA release

   Update the default Smile CDR version in preparation for the `YYYY.MM` quarterly GA release.

   The 'default' test output was updated due to the changed version.

   Breaking Change: Default GA release of Smile CDR changed from `YYYY.MM` to `YYYY.MM`"
   ```

* (Optional) Re-run pre-commit check:
   Re-running the commit check ensures that your commit message is formatted correctly.
   ```
   make pre-commit
   ```

* Push to origin (Your forked repository)
   ```
   git push origin
   ```

### Create Merge Request in Upstream Repository

Open an MR in GitLab:
* Source: `my-namespace/smile-dh-helm-charts:208-improve-developer-documentation`
* Target: `smilecdr-public/smile-dh-helm-charts:next-major`

After your Merge Request has been created, someone with the maintainer role will run the merge pipeline to verify that there are no regressions with the new code.
* The merge request will be reviewed by a repo maintainer
* The merge pipeline will be initiated by a repo maintainer
* Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
* The automatic release process will run, releasing a new version of the Helm Chart if required
* The automatic documentation update process will run, updating the live documentation site
* The `upstream/next-major` branch is now ready for contributions via feature branches.

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

Before publishing to the `stable` release channel, ensure no references to pre-release versions of Smile CDR remain in the code.

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
    "2025.05" (dict "name" "Fortification" "latest" "R01") <-- Add this line to support `2025.05.R01` and above
    "2025.02" (dict "name" "Transfiguration" "latest" "R03")
    "2024.11" (dict "name" "Despina" "latest" "R05")
    "2024.08" (dict "name" "Copernicus" "latest" "R05")
    "2024.05" (dict "name" "Borealis" "latest" "R05")
    "2024.02" (dict "name" "Apollo" "latest" "R07")
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

#### Review Migration Guide
**Source**: `docs/upgrading/index.md`

Review the 'Migration Guides' section for this upgrade to ensure that it covers any extra steps required for migrating to this version of the Helm Chart.

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
   git commit -am "chore(smilecdr): Prepare release for v5.0

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
* The merge request will be reviewed by a repo maintainer
* The merge pipeline will be initiated by a repo maintainer
* Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
* The automatic release process will run, releasing a new version of the Helm Chart if required
* The automatic documentation update process will run, updating the live documentation site
* The `upstream/next-major` branch will now have the correct version for future feature branches.

### Create Merge Request to `main` Branch

>Note: This step will be performed by a repository maintainer when we are ready to publish the release

Open an MR in GitLab:
- Source: `smilecdr-public/smile-dh-helm-charts:next-major`
- Target: `smilecdr-public/smile-dh-helm-charts:main`

After the Merge Request is created, the merge pipeline will automatically run to verify that there are no regressions with the new code.
* Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
* The automatic release process will run, releasing the new major version of the Helm Chart
* The automatic documentation update process will run, updating the 'latest' documentation site
* The `upstream/main` branch will now reflect the new Helm Chart version.

### Mergeback `main` to `next-major`

>Note: This step will be performed by a repository maintainer after the release has been published

The automated release process will create a new commit on the `main` branch, which means that it will now be ***ahead*** of `next-major`. To fix this, `main` needs to be merged into `next-major` before work can proceed on the next upcoming major release of the Helm Chart.
