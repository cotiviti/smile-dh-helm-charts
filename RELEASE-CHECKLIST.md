# Release Process Checklist
This checklist outlines the required steps for managing a new major release of the Smile CDR Helm Chart.

## 🔀 1. Start a New Major Release

### Prepare Release Branch
If the previous release has just been published, ensure that the `next-major` branch is ready for continuing development of the new release.

* Merge-back `main` into `next-major` - Currently performed by a repo maintainer after a release is published.

### Create Initial Feature Branch For New Release

```
git checkout -b nnn-add-support-for-smilecdr-yyyy-mm
```

### Update Version References

* `src/main/charts/smilecdr/Chart.yaml` - Set `appVersion` to the appropriate Smile CDR version.
* `src/main/charts/smilecdr/templates/scdr/_scdr-feature-gate.tpl` - Add appropriate entry in the `smilecdr.releases` template


### Update Documentation References

* `mkdocs/macros/main.py` - Add an entry under `version_info` to represent the new version of the Helm Chart and Smile CDR. This gets used throughout the documentation to display version information.

### Prepare initial commit for release

Create the initial commit for the new release branch. It's important that this commit includes a breaking change so that the Semantic Versioning process bumps the major version.

* Update test outputs, review and stage changes:
   ```
   make helm-update-outputs
   ```
* Lint and run tests:
   ```
   make pre-commit
   ```
* Commit (Note this is a multi-line commit):
   ```
   git commit -am "feat(smilecdr): add support for smilecdr yyyy-mm release

   This commit bumps the Helm Chart major version to vx.0.0

   Breaking Change: Updated Smile CDR from Version x to y"
   ```
* Push to origin (Forked repository)

### Create Merge Request in Upstream Repository

After this initial commit is merged, the release pipeline will bump the version. The `upstream/next-major` branch will then have the correct version for future feature branches.

📘 2. Update Code and Documentation

Follow the iterative development process for this version, creating feature branches from `upstream/next-major` to add features and update documentation.

✅ 3. Finalize and Publish Release

Section still under review...
