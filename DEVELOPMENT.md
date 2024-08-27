# Developing Smile Digital Health Helm Charts

If you plan to contribute to these Helm Charts, these guidelines
will get you started.
## Repository Layout
This repository only contains the one chart right now (Smile CDR) but
may house more charts as we release them.

All charts are located in ```src/main/charts/<chartname>```
Tests are located in ```src/test/helm-output/<chartname>```

## Required Developer Tools
This repository has a rigid SDLC that enforces the following:
* Commit messages must follow the [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/) patterns in order to provide a meaningful commit history and to automate the versioning & release process.
* Unit testing framework that helps avoid regression errors in generated
Kubernetes manifests
* Automatic generation of the official [documentation](https://smilecdr-public.gitlab.io/smile-dh-helm-charts/v1.0.0-pre) using [mkdocs](https://www.mkdocs.org/).

In order to perform development tasks on this repository, you must install the following utilities.

* [Helm](https://helm.sh/)
* [Helm Docs](https://github.com/norwoodj/helm-docs)
* [Dyff](https://github.com/homeport/dyff) - Used for comparing semantic meaning of YAML manifests in the Helm Output tests
* [jq](https://jqlang.github.io/jq) - Used for parsing Helm Output yaml test configurations
* [yq](https://mikefarah.gitbook.io/yq) - Required to reliably convert yaml configurations into json for jq
* [mkdocs](https://www.mkdocs.org/) - For generating Smile CDR Helm Chart [docs](https://smilecdr-public.gitlab.io/smile-dh-helm-charts/v1.0.0-pre/)
* [Shellcheck](https://www.shellcheck.net/) - Used for linting shell scripts used in build & CI process
* [Pre-commit](https://pre-commit.com/) - Used to maintain integrity of repository. e.g. For enforcing Conventional Commits and performing local linting and unit tests.

### Developer tools quickstart

If using a Mac or linux machine with [Homebrew](https://brew.sh/), you can simply run the following commands to prepare your environment.

```
brew install helm homeport/tap/dyff norwoodj/tap/helm-docs jq yq pre-commit shellcheck
```

<!-- The following installs a Python ***virtual environment*** so that you can install the required commitizen and MkDocs python packages.
```
virtualenv venv
. ./venv/bin/activate
pip install -r commitizen-requirements.txt -r mkdocs-requirements.txt
``` -->

>***Note:*** If you are not able to use Homebrew to install these dependencies, you will need to go through the list of required tooling up above and install them separately.

To check that all required tools are correctly installed, you can run the following:

```
make pre-commit
```

If you are on the `pre-release` branch, this should complete without error.

## Release Strategy
Although we can release directly to the `main` branch using the
`Semantic release` tool, we have chosen to use a `pre-release`
branch for now in order to control the release cadence.

In the future, when chart development slows, we may switch to
releasing on the `main` branch.
## Development Process
To contribute changes to this repo, do the following:
* Create a GitLab issue [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/new)
* Create a merge request and feature branch from the new issue
* On your local development workstation, pull and checkout the newly created branch
* Make and test your changes.
  * Be sure to work on a single small-scope feature at once. If it can't be described well in a single commit, the scope of work is too great.
  * Squash your commits into one meaningful commit that follows the `conventional commits` standards
  * Add tests for your code changes if possible
  * Run the tests with `make helm-check-outputs` and ensure that the expected outputs did not unexpectedly change
  * Run `make pre-commit` as before

## Writing Commit Messages
When contributing to this repository, there is a strict guideline for checking in code. This helps keep the repository well organized and makes the versioning and release process reliable and low maintenance.

### Conventional Commits
You should follow the following `Conventional Commit` structure:

`type(scope): description`

For this repository, the following can be used for the `type`:
* `fix` - Bug fixes
* `feat` - Adding new features or functionality
* `refactor` - When refactoring code with no semantic changes to output
* `style` - When adjusting code styles (Whitespace, indentation etc). No semantic changes to output
* `chore` - Misc changes that do not affect functionality
* `revert` - Reverting previous changes
* `test` - Updating expected outputs. Changes may just be included in a `fix` or `feat` commit.
* `docs` - Updating documentation.
* `build`- Updates to build process
* `ci` - Updates to pipeline

For the `scope`, use something like the following:
* `smilecdr` - Core Smile CDR Helm Chart functionality
* `pgo` - Functionality pertaining just to the Postgres Operator
* `strimzi` - Functionality pertaining just to the Strimzi Kafka Operator
* `observability` - Changes related to the observability suite

The idea here is to identify which component here is being affected. If there are multiple affected components, you may need to consider breaking your changes into smaller, more manageable, commits.

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

If you do need to add a breaking change, then do so by adding a footer in your commit message like so:
```
Breaking Change - Did a thing that breaks the thing.
```

### Checking your commits
You should always check your commits before pushing them to the GitLab repository, to ensure they are appropriately structured.
```
make cz-check
```

## Documentation
The Smile CDR documentation is generated using [mkdocs](https://www.mkdocs.org/) and currently uses the [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme.

The documentation lives in the `./docs/` directory and can be 'live-edited' while viewing the docs on your local workstation.

### Running local MkDocs development server

#### Using Makefile
The included `makefile` has been configured to allow simple starting of the MkDocs development server by simply running:
```
make mkdocs-serve
...
INFO    -  [11:25:45] Watching paths for changes: 'docs', 'mkdocs.yml'
INFO    -  [11:25:45] Serving on http://127.0.0.1:8000/smile-dh-helm-charts/
```
This will automatically create the Python Virtual environment if not already done so.

You can now view the documentation on the provided URL and make live updates.

If you cannot use `make`, or would like to perform the steps manually, use the steps that follow.

#### Prepare Environment
>**Note:** You only need to run this once to install the dependencies, if you did not already do it further up
```
virtualenv venv
. ./venv/bin/activate
pip install -r mkdocs-requirements.txt
```

#### Start the local development server
```
. ./venv/bin/activate
mkdocs serve
...
INFO    -  [11:25:45] Watching paths for changes: 'docs', 'mkdocs.yml'
INFO    -  [11:25:45] Serving on http://127.0.0.1:8000/smile-dh-helm-charts/
```

You can now view the documentation on the provided URL and make live updates.
