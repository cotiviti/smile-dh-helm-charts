# Developing this Terraform module

Follow this guide if you wish to contribute to developing the code in this repository.

## Getting Started

### Required tools

To contribute to this module, you will need the following tools installed on your workstation

* [pre-commit](https://pre-commit.com/)
* [Terraform](https://terraform-docs.io/)
* [tf-lint](https://github.com/terraform-linters/tflint)

### Quickstart on Mac

```sh
brew install pre-commit
brew install terraform-docs
brew install tflint
```

## Committing Code

* Do not make changes directly on main or pre-release branches
* Create an issue in GitLab
* Create a Merge Request
* Check out the new feature branch locally
* Keep changes small. Only include one change per feature branch
* Commit often, but squash your commits before pushing
* Run pre-commit before committing code to be pushed
* Use Conventional Commit techniques to format meaningful commit messages
