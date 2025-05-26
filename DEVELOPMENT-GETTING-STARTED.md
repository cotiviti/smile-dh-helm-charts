# Developing Smile Digital Health Helm Charts

Welcome to the Smile Digital Health Helm Charts repository! This guide is designed to help contributors — regardless of prior software development experience — get started with contributing to the charts efficiently and confidently.

---

## Repository Location

The official repository for the Smile CDR Helm Chart is [https://gitlab.com/smilecdr-public/smile-dh-helm-charts](https://gitlab.com/smilecdr-public/smile-dh-helm-charts)

**WARNING DO NOT clone this repository!**

If you clone this repo directly, it will be set as your `origin` which will complicate following the instructions.
Follow the repository setup section below to begin working in this repo.

## Repository Structure

This repository currently contains a single chart (`Smile CDR`), but it is structured to accommodate more charts in the future.

- **Charts Directory:** `src/main/charts/<chart-name>`
- **Test Output Directory:** `src/test/helm-output/<chart-name>`
- **Documentation:**
   * `docs` - Main Documentation site source code. Uses MkDocs
   * `mkdocs.yml` - Main configuration file for docs
   * `mkdocs-requirements.txt` - Python packages for MkDocs and its plugins
   * `mkdocs` - MkDocs macros (For generating version information in docs)
- **Build and Release Scripts:**
   * `.semver-release` - Configuration for Semantic Release process
   * `scripts` - Various scripts for build and release tooling
- **Helm Chart Examples:** `examples`

---

## Required Tools

To contribute effectively, you'll need certain command-line tools installed. These are required for tasks such as rendering Helm templates, validating outputs, linting, and generating documentation.

>**Note:** The following instructions assume that you are working on a MacBook workstation. If you are using a different platform, some extra investigation may be required to get some components working correctly.

### Tools List

|                       Tool                         |                     Purpose                          |
| -------------------------------------------------- |----------------------------------------------------- |
| [Helm](https://helm.sh/)                           | Template and package manager for Kubernetes charts   |
| [Helm Docs](https://github.com/norwoodj/helm-docs) | Auto-generates README documentation for Helm charts  |
| [Dyff](https://github.com/homeport/dyff)           | Compares semantic differences between YAML documents |
| [jq](https://jqlang.github.io/jq)                  | Parses JSON-formatted output                         |
| [yq](https://mikefarah.gitbook.io/yq)              | Converts YAML to JSON for use with `jq`              |
| [mkdocs](https://www.mkdocs.org/)                  | Builds and serves documentation websites             |
| [python3](https://www.python.org/)                 | Used for general scripting                           |
| [python virtualenv](https://www.python.org/)       | Used for hosting mkdocs documentation locally        |
| [Shellcheck](https://www.shellcheck.net/)          | Lints shell scripts                                  |
| [Pre-commit](https://pre-commit.com/)              | Automates local checks for commit message format, code linting, etc.   |

You will install these tools in the [Initial Repository & Workstation Setup](#initial-repository--workstation-setup) section below

---

## Contribution Workflow Overview

The Smile Digital Health Helm Charts use a forked branching model to enable collaboration and contributions to the project.

To make contributions, you must follow the below steps:
* Create a GitLab Issue
* Create a feature branch
* Develop your feature
* Commit and push your feature branch to your forked repository (your `origin` remote)
* Create a Merge Request from your feature branch on your forked repo to the main repository
* Repository maintainer will review and trigger automated release process

>**Note:** Contribution cannot be done directly to the official repository. A forked repo as per the above MUST be used.

In order to follow this workflow, you must have your local development workstation set up with the correct `origin` and `upstream` remotes as per the below instructions.

---

## Initial Repository & Workstation Setup

### Fork The Smile CDR Helm Charts Repository
Before working on features, you should fork the official Smile CDR Helm Charts repository. This forked repository will be used to facilitate the creation of Merge Requests for your feature branches.

* This forked repository will be configured as the `origin` remote on your local development workstation.
* The official Smile Digital Health Helm Charts repository will be configured as the `upstream` remote on your local development workstation.
<!-- * It is not essential for this forked repository to be fully up to date with the official repository. -->

With this configuration, you will be able to follow the contribution workflow documented below.

You can either create a fork in your organization if you are working in a team with multiple contributors (recommended), or you can create a new private fork of the repository if you are an individual contributor.

#### Use Existing Repository Fork
If working in a team, you should seek to use an existing fork of the repository if available.

#### Create New Repository Fork
If no existing fork is available then you should create one here:
[https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/forks/new](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/forks/new)

>Note: Do not worry about messages in your forked repository about it not being synced with the upstream. This is a GitLab quirk that can be safely ignored when using the workflow described here.

<!-- **WARNING!** You ***SHOULD NOT*** use the GitLab UI as a reference for the current status of the release branches in your forked repo as it can be misleading. This is because the GitLab UI currently compares branches on forked repositories with the default branch of the upstream repository and ***not*** the respective release branch. This results in a message that makes it seem that the release branch (e.g. `next-major`) in your forked repo is not in sync with the upstream repo, even if it is. You ***MUST NOT*** use the GitLab sync button in such scenarios as it will incorrectly pull changes from `upstream/main` into your feature or release branch, which can cause confusion. -->

### Clone Forked Repository

The first time you work on this repository on your local workstation, you need to correctly configure your git remotes so that you can create your feature branches from the appropriate release branch of the official repository.

* Clone your forked repository to your local workstation
   ```
   git clone https://gitlab.com/my-namespace/smile-dh-helm-charts.git
   ```
   > This will configure your forked repository as the `origin` remote on your workstation.

* Add a git remote for the upstream repository
   ```
   cd smile-dh-helm-charts
   git remote add upstream https://gitlab.com/smilecdr-public/smile-dh-helm-charts.git
   ```
   > This will configure the official repository as the `upstream` remote on your workstation.

### Set Up Development Tools (macOS / Linux)

If you are using [Homebrew](https://brew.sh/), run:

```sh
brew install helm homeport/tap/dyff norwoodj/tap/helm-docs jq yq pre-commit shellcheck virtualenv
```

>**Note:** If you are unable to use Homebrew, you will need to manually install each tool from its official site.

<!-- To install Python dependencies for commit messages and docs:

```sh
python3 -m venv venv
. ./venv/bin/activate
pip install -r commitizen-requirements.txt -r mkdocs-requirements.txt
``` -->

### Verify Tools

To verify that the tools are installed and functioning correctly:

* Switch to a suitable branch. e.g. `next-major`
   ```sh
   git fetch upstream
   git switch next-major
   ```

* Run the pre-commit checks
   ```sh
   make pre-commit
   ```
   >Note: The `check_helm_outputs` step may take several minutes to complete. Feel free to run the following checks in a new shell while you wait for this to complete.

* Launch the local documentation server
   ```sh
   make mkdocs-serve
   ```

✅ If you're on one of the official release branches, these commands should complete without error.

### You're Ready To Go!

Congratulations!

You are now ready to start working on features!

<!-- **Optional:** Choose and Sync Source Branch
> **WARNING!** You ***SHOULD*** only do this step using the git commands above. You ***SHOULD NOT*** use the GitLab UI as a reference for the current status of non-default branches in your forked repo as it can be misleading. This is because the GitLab UI currently compares forked branches with the default branch of the upstream repository and ***not*** the respective feature branch. This results in a message that makes it seem that the release branch (e.g. `next-major`) in your forked repo is not in sync with the upstream repo, even if it is.
- Ensure that the `next-major` branch in your forked repository is up to date as follows:
   ```
   git checkout next-major
   git pull upstream next-major
   git push origin next-major
   ``` -->

---

## Summary Checklist for New Contributors ✅

- [ ] All required tools are installed
- [ ] Local clone and git remotes set up correctly
- [ ] `make pre-commit` passes
- [ ] Local documentation server runs

---

## Next Steps

Now you should refer to the [Contribution Workflow](./DEVELOPMENT-WORKFLOW.md) document to start working on the charts.

Before working on or adding features to the Helm Chart, you should familiarize yourself with the design and some of the code standards being used.

Refer to the [Design Doc](./DESIGN.md) for info on this.

## Need Help?

If you're stuck or unsure, reach out to a maintainer, ask questions in the issue thread, or browse past merge requests for examples.

Welcome to the team, ***!!Happy Hacking!!*** 🛠️
