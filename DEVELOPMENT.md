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
   - If you have already forked the repository, make sure your fork is up to date.
3. **Create a Feature Branch**:
   - Create a feature branch in your forked repository
   - Refer to the branching strategy to choose your source branch
      - Typically you will branch from the `pre-release` branch
   - Include the GitLab Issue in your feature branch - e.g. `208-improve-developer-documentation`
4. **Develop Locally**:
   - Clone your forked repository and checkout your newly created feature branch.
   - Make small focused changes (keep each MR small and isolated)
   - Write/update documentation in `docs/`
5. **Run Tests**:
   - Write/update tests in `src/test/helm-output/`
   - Run tests using:
     ```sh
     make helm-check-outputs
     ```
6. **Prepare, Push and Submit**
   - Commit your changes following the commit message rules (see below)
     - Squash multiple commits for a related change into one meaningful commit
   - Check commit structure using:
     ```sh
     make pre-commit
     ```
   - Push your commit
7. **Create Merge Request**
   - Create merge request to merge your new branch to the source branch
   - Merge request to the main repository, NOT your forked repository
8. **Review, Update, Merge**
   - Merge pipelines will run to check that there are no errors or regressions with the new code
   - The merge request will be reviewed by an approved reviewer
   - Once accepted, the merge request will be accepted
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
