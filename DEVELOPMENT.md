# Developing Smile Digital Health Helm Charts

Welcome to the Smile Digital Health Helm Charts repository! This guide is designed to help contributors — regardless of prior software development experience — get started with contributing to the charts efficiently and confidently.

---

## Repository Structure

This repository currently contains a single chart (`Smile CDR`), but it is structured to accommodate more charts in the future.

- **Charts Directory:** `src/main/charts/<chart-name>`
- **Test Output Directory:** `src/test/helm-output/<chart-name>`

---

## Required Tools

To contribute effectively, you'll need a set of command-line tools. These are required for tasks such as rendering Helm templates, validating outputs, linting, and generating documentation.

### Tool List

| Tool        | Purpose                                                                 |
|-------------|-------------------------------------------------------------------------|
| [Helm](https://helm.sh/)        | Template and package manager for Kubernetes charts                      |
| [Helm Docs](https://github.com/norwoodj/helm-docs)   | Auto-generates README documentation for Helm charts                    |
| [Dyff](https://github.com/homeport/dyff)        | Compares semantic differences between YAML documents                   |
| [jq](https://jqlang.github.io/jq)          | Parses JSON-formatted output                                            |
| [yq](https://mikefarah.gitbook.io/yq)          | Converts YAML to JSON for use with `jq`                                |
| [mkdocs](https://www.mkdocs.org/)      | Builds and serves documentation websites                               |
| [Shellcheck](https://www.shellcheck.net/)  | Lints shell scripts                                                    |
| [Pre-commit](https://pre-commit.com/)  | Automates local checks for commit message format, code linting, etc.   |

### Quick Setup (macOS / Linux)

If you are using [Homebrew](https://brew.sh/), run:

```sh
brew install helm homeport/tap/dyff norwoodj/tap/helm-docs jq yq pre-commit shellcheck
```

To install Python dependencies for commit messages and docs:

```sh
python3 -m venv venv
. ./venv/bin/activate
pip install -r commitizen-requirements.txt -r mkdocs-requirements.txt
```

To verify everything is working:

```sh
make pre-commit
```

> ✅ If you're on one of the official release branches, this should complete without errors.

> **Note:** If you can't use Homebrew, manually install each tool from its official site.

---

## Release Strategy

This repository uses a well defined branching strategy along with `Semantic release` to maintain control and stability.

---

## Contributing Workflow

To propose and implement changes:

1. **Create a GitLab Issue**:
   - Start [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/new)
   - Use the provided [issue template](./ISSUE-TEMPLATE.md) as a starting point
2. **Fork the Repository**:
   - [https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/forks/new](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/forks/new)
   > **WARNING!** You ***SHOULD NOT*** use the GitLab UI as a reference for the current status of the release branches in your forked repo as it can be misleading. This is because the GitLab UI currently compares branches on forked repositories with the default branch of the upstream repository and ***not*** the respective release branch. This results in a message that makes it seem that the release branch (e.g. `pre-release`) in your forked repo is not in sync with the upstream repo, even if it is. You ***MUST NOT*** use the GitLab sync button in such scenarios as it will incorrectly pull changes from `upstream/main` into your feature or release branch, which can cause confusion.
3. **Set up Local Development Environment**

   The first time you work on this repository on your local workstation, you need to configure the upstream repository so that you can create your feature branches from the appropriate release branch.
   - Clone your forked repository to your local workstation
      ```
         git clone https://gitlab.com/simpatico.ai/my-namespace/smile-dh-helm-charts.git
      ```
      > This will configure your forked repository as the `origin` remote
   - Add a git remote for the upstream repository
      ```
      cd smile-dh-helm-charts
      git remote add upstream https://gitlab.com/smilecdr-public/smile-dh-helm-charts.git
      ```
   <!-- **Optional:** Choose and Sync Source Branch
   > **WARNING!** You ***SHOULD*** only do this step using the git commands above. You ***SHOULD NOT*** use the GitLab UI as a reference for the current status of non-default branches in your forked repo as it can be misleading. This is because the GitLab UI currently compares forked branches with the default branch of the upstream repository and ***not*** the respective feature branch. This results in a message that makes it seem that the release branch (e.g. `pre-release`) in your forked repo is not in sync with the upstream repo, even if it is.
   - Ensure that the `pre-release` branch in your forked repository is up to date as follows:
      ```
      git checkout pre-release
      git pull upstream pre-release
      git push origin pre-release
      ``` -->

5. **Create your Feature Branch**:

   Refer to the branching model to decide which release branch to create your feature branch from.

   > If you are unsure which branch to use, just use the `pre-release` branch, unless you know you are working on a breaking change or a feature that is already planned for some future release.

   The following instructions assume you are working from the `pre-release` branch.

   - Include the GitLab Issue in your feature branch - e.g. `208-improve-developer-documentation`
   - Create your feature branch in your forked repository. e.g.:
      ```
      git checkout -b 208-improve-developer-documentation upstream/pre-release
      ```
6. **Develop Locally**:
   - Clone your forked repository and checkout your newly created feature branch.
   - Make small focused changes (keep each MR small and isolated)
   - Write/update documentation in `docs/`
7. **Run Tests**:
   - Write/update tests in `src/test/helm-output/`
   - Run tests using:
      ```sh
      make helm-check-outputs
      ```
8. **Prepare and Commit**
   - Commit your changes following the commit message rules (see below)
     - Squash multiple commits for a related change into one meaningful commit
   - Check commit structure using:
      ```sh
      make pre-commit
      ```
   - Commit your changes
      ```
      git add .
      git commit -m "docs(contrib): add development workflow documentation"
      ```
   - Resolve any conflicts with upstream changes

      If you have been working on your feature branch for some time, there may have been changes introduced upstream. You need to pull the latest changes and resolve any conflicts.
      ```
      git pull upstream pre-release --rebase
      ```
9. **Push Feature Branch To Your Forked Repository**

9. **Create Merge Request**

   When you’re ready to propose your changes:

   Open an MR in GitLab:
   - Source: `my-namespace/smile-dh-helm-charts:208-improve-developer-documentation`
   - Target: `smilecdr-public/smile-dh-helm-charts:pre-release`

10. **Review, Update, Merge**

   After your Merge Request has been created, a pipeline will run to verify that there are no regressions or regressions with the new code.
   - The merge request will be reviewed by an approved reviewer
   - Once pipelines pass and the changes have been accepted, the maintainer will complete the merge request
   - The automatic release process will run, releasing a new version of the Helm Chart if required
   - The automatic documentation update process will run, updating the live documentation site

---

## Commit Message Format

These Helm Charts use the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** format for clarity and automation.

### Format
```
type(scope): short description
```

#### Example
```sh
feat(smilecdr): add support for configurable FHIR endpoints
```

### Valid Types
- `fix` – Bug fix
- `feat` – New feature
- `refactor` – Code reorganization with no output changes
- `style` – Formatting only (whitespace, indentation, comments)
- `chore` – Miscellaneous tasks
- `revert` – Reverts a previous commit
- `test` – Output test changes
- `docs` – Documentation updates
- `build` – Build process changes
- `ci` – Continuous integration pipeline changes

### Valid Scopes
- `smilecdr` - Core Smile CDR Helm Chart functionality
- `pgo` - (PostgreSQL Operator)
- `strimzi` - (Kafka Operator)
- `observability` - Included observability suite

> 🔍 Tip: Use precise scopes to help reviewers understand the affected component. Break large changes into multiple commits if needed.

### Breaking Changes
Avoid breaking changes unless absolutely necessary, as they will result in a major version bump in the Helm Chart.

As such, the introduction of breaking changes should align with planned major version updates.

If a breaking change needs to be released before a planned major release, it should be done in a non-invasive way, such as:
* Enabling breaking features with feature flags
* Maintaining old behaviour as the default, but add non-intrusive deprecation warnings

Do declare a change as breaking, include a footer in your commit:
```sh
BREAKING CHANGE: Changing behavior of xyz component
```

---

## Testing Changes

Before submitting your changes:

1. Run `make helm-check-outputs` to compare output manifests
2. Review diffs carefully — avoid unintended output changes
3. Run `make pre-commit` to enforce all local checks and linting

---

## Documentation Development

Documentation is auto-generated using [MkDocs](https://www.mkdocs.org/) + [Material theme](https://squidfunk.github.io/mkdocs-material/).

- Document source code lives in: `./docs/`
- Documents are published here: https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/

### Editing Docs Locally

To ease the process of editing the docs, you can run a live local version that updates in realtime as you make changes to the documentation source code.

This local environment can be created automatically using the `makefile` or you can create the environment manually.

#### Using Makefile
```sh
make mkdocs-serve
```
- Local version of docs available at: http://127.0.0.1:8000/smile-dh-helm-charts/

> 💡 Changes you make in the `docs/` folder will reload automatically.

#### Manual Setup
```sh
python3 -m venv venv
. ./venv/bin/activate
pip install -r mkdocs-requirements.txt
mkdocs serve
```

---

## Summary Checklist for New Contributors ✅

- [ ] All required tools are installed
- [ ] Created an issue and merge request
- [ ] Changes are small and focused
- [ ] Tests added/updated if needed
- [ ] Documentation updated if needed
- [ ] Commit messages use the correct format
- [ ] `make pre-commit` passes

---

## Next Steps

Before working on or adding features to the Helm Chart, you should familiarize yourself with the design and some of the code standards being used.

Refer to the [Design Doc](./DESIGN.md) for info on this.

## Need Help?

If you're stuck or unsure, reach out to a maintainer, ask questions in the issue thread, or browse past merge requests for examples.

Welcome to the team! 🛠️
