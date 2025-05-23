# Smile Digital Health Helm Charts Contribution Workflow

This document serves as a working reference to be used when working on feature requests for the Smile Digital Health Helm Charts.

## Prerequisites
Before starting work on contributing features, make sure you have read the  [Getting Started Guide](./DEVELOPMENT-GETTING-STARTED.md) and set up your local environment.

## Contribution Workflow

To propose and implement changes:

1. **Create a GitLab Issue**:
   - Start [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/issues/new)
   - Use the provided [issue template](./ISSUE-TEMPLATE.md) as a starting point

2. **Create your Feature Branch**:

   Refer to the branching model to decide which release branch to create your feature branch from.

   > If you are unsure which branch to use, just use the `next-major` branch, unless you know you are working on a breaking change or a feature that is already planned for some other future release.

   The following instructions assume you are working from the `next-major` branch.

   - Include the GitLab Issue in your feature branch - e.g. `208-improve-developer-documentation`
   - Create your feature branch on your local clone. e.g.:
      ```
      git checkout -b 208-improve-developer-documentation upstream/next-major
      ```

3. **Develop Locally**:

   - Make small focused changes (keep each MR small and isolated)
   - Write/update documentation in `docs/`

4. **Run Tests**:

   Before submitting your changes, you should run the regression testing suite to check for unexpected changes in the templates that get rendered by the Helm Chart.

   - Write/update tests in `src/test/helm-output/`
   - Check test outputs using:
      ```sh
      make helm-check-outputs
      ```
   - You can also update the test outputs using:
      ```sh
      make helm-check-outputs
      ```
   >Warning: When updating test outputs, you need to thoroughly review the changes to ensure there are no unexpected outputs.

5. **Prepare and Commit**

   Before writing commit messages, review the [Commit Messages Guide](./DEVELOPMENT-COMMIT-MESSAGES.md)

   - Perform pre-commit checks using:
      ```sh
      make pre-commit
      ```
      >Note: This may update some files, e.g. removing unnecessary whitespace etc.

   - Commit your changes following the commit message rules (see below)
     - Squash multiple commits for a related feature/change into one meaningful commit

   - Commit your changes
      ```
      git add .
      git commit -m "docs(contrib): Add development workflow documentation"
      ```

   - Check commit structure using:
      ```sh
      make pre-commit
      ```

   - Resolve any conflicts with upstream changes

      If you have been working on your feature branch for some time, there may have been changes introduced upstream. You need to pull the latest changes and resolve any conflicts.
      ```
      git pull upstream next-major --rebase
      ```

6. **Push Feature Branch To Your Forked Repository**
   ```
   git push origin
   ```

9. **Create Merge Request**

   When you’re ready to propose your changes:

   Open an MR in GitLab:
   - Source: `my-namespace/smile-dh-helm-charts:208-improve-developer-documentation`
   - Target: `smilecdr-public/smile-dh-helm-charts:next-major`

10. **Review, Update, Merge**

   After your Merge Request has been created, someone with the maintainer role will run the merge pipeline to verify that there are no regressions with the new code.

   * The merge request will be reviewed by an approved reviewer
   * The merge pipeline will be initiated by a repo maintainer
   * Once pipelines pass and the changes have been accepted, a repo maintainer will complete the merge request
   * The automatic release process will run, releasing a new version of the Helm Chart if required
   * The automatic documentation update process will run, updating the live documentation site


## Contribution Checklist

- [ ] Created an issue and merge request
- [ ] Changes are small and focused
- [ ] Tests added/updated if needed
- [ ] Documentation updated if needed
- [ ] Commit messages use the correct format
- [ ] `make pre-commit` passes

---

## Need Help?

If you're stuck or unsure on any of the above steps, reach out to a maintainer, ask questions in the issue thread, or browse past merge requests for examples.

Happy Hacking!
