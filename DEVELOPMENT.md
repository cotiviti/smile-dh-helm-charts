# Developing Smile Digital Health Helm Charts

If you plan to contribute to these Helm Charts, these guidelines
will get you started.
## Repository Layout
This repository only contains the one chart right now (Smile CDR) but
will house more charts as we release them.

All charts are located in ```src/main/charts/<chartname>```
Tests are located in ```src/test/helm-output/<chartname>```

## Required Developer Tools
This repository has a fairly rigid SDLC that enforces:
* "Conventional Commit" commit messages to automate the versioning
and release process.
* Testing framework that helps avoid regression errors in generated
k8s manifests

For these to work well, the following tools are recommended:
* Helm
* Helm Docs
* Dyff, jq, yq
* Pre-commit

## Release Strategy
Although we can release directly to the `main` branch using the
`Semantic release` tool, we have chosen to use a `pre-release`
branch for now in order to control the release cadence.

In the future, when chart development slows, we may switch to
releasing on the `main` branch.
## Development Process
To contribute changes to this repo, do the following:
* Create a GitLab issue
* Create a feature branch and merge request for the branch
* Check out your code and make your changes.
  * Be sure to work on a single small-scope feature at once. If it can't be described well in a single commit, the scope of work is too great.
  * Squash your commits into one meaningful commit that follows the `conventional commits` standards
  * Add tests for your code changes if possible
  * Run the tests and make sure the expected outputs did not unexpectedly change

### Breaking Changes
Try to find a way to not introduce breaking changes.

Breaking changes may include:
* Changes to the semantic meaning of rendered outputs if no inputs (Values files) were altered
* Changes that require the inputs (values files) to be modified to prevent unwanted output changes

Breaking changes bump the major version.
To avoid regular major version bumps, breaking changes can be avoided by:
* Enabling breaking features with feature flags
* Maintaining old behaviour as the default, but add non-intrusive deprecation warnings
* Multiple breaking changes can be bundled together in version releases in a controlled cadence.
