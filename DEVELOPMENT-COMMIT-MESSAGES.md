# Smile Digital Health Helm Charts Commit Messages

This document serves as a working reference to be used when writing suitable commit messages for the Smile Digital Health Helm Charts.

---
## Conventional Commits
This repository use the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** format for clarity and to enable the automated release processes.

### Release Automation
By using these conventions, the release process is handled automatically.

This means that by investing in a little more effort upfront when creating commits, we greatly reduce the effort in deciding when and how to bump versions and publish new releases.

### Meaningful Git History

Disorganised commit messages can make it challenging to follow the history of a Git repository.
[This XKCD comic](https://xkcd.com/1296/) captures the essence of this problem quite nicely :) 

![image](https://imgs.xkcd.com/comics/git_commit.png)

[This Post](https://cbea.ms/git-commit/) explains the issue a little more concisely!

## Commit Message Format

In order for this to work as intended, it is important that commit messages follow a specific structure.

The following guidelines follow [Conventional Commits 1.0.0 Summary](https://www.conventionalcommits.org/en/v1.0.0/#summary) and [How to Write a Git Commit Message](https://cbea.ms/git-commit/)

Please review these resources to familiarize yourself with the concepts.

### Format
Commit messages should follow the following format.
```
type(scope): Short imperative mood description

Detailed description what was changed and why.
These details should clarify the intent of this commit.

If there are changes to the test outputs, explain them here.

Breaking Change: Use this footer if there is a breaking change.
```

Trivial changes may use a single line if required.

Refer to the Conventional Commits [Summary](https://www.conventionalcommits.org/en/v1.0.0/#summary) for more details and scenarios.

#### Commit Subject Line Message

The actual commit message (i.e. after `type(scope):`) should:
* Be in the imperative mood
* Begin with an upper-case verb in the imperative tense
* Not contain a period (`.`) at the end

See [How to Write a Git Commit Message](https://cbea.ms/git-commit/) for a good explanation for using these conventions.

#### Example
```
feat(smilecdr): Add support for Smile CDR `2025.05` GA release

This commit bumps the Helm Chart major version to v5.0.0

The 'default' test output was updated due to the changed version.

Breaking Change: Default GA release of Smile CDR changed from `2025.02` to `2025.05`
```

### Commit Message Types and Release Notes
All commits with `feat` or `fix` types will be displayed in the release notes for the release.

Consider this when writing the commit message title, as it needs to make sense and be easy to understand when looking at the changelog and release notes. This is one of the reasons that the upper cased imperative mood is important.

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

To declare a change as breaking, include a footer in your commit:
```sh
Breaking Change: Changing behavior of xyz component
```

Note that the message used here will appear in the Release Notes for this release, so choose the wording appropriately.

---

## Commit Message Checklist

- [ ] Changes are small and focused on a single feature/change
- [ ] Correct commit message `type` used
- [ ] Correct commit message `scope` used
- [ ] Commit message subject line [follows the imperative mood](https://cbea.ms/git-commit/#imperative)
- [ ] Commit message body contains any information that may clarify the change
- [ ] Commit message body explains any changes in tests output
- [ ] Breaking Changes footer summarizes the breaking change
- [ ] `make pre-commit` passes

---

## Need Help?

If you're stuck or unsure on any of the above steps, reach out to a maintainer, ask questions in the issue thread, or browse past merge requests for examples.

Happy Hacking!
