# Release Channels

The Smile CDR Helm Charts are available in a number of release channels.

| Release Type | Channel Name | Helm Chart Repo |
| ------------ | ------------ | --------------- |
| Official | `stable` | {{ helm_repo_stable }} |
| v1.x prereleases | `devel` | {{ helm_repo_devel }} |
| v2.x and up prereleases | `pre-release` | {{ helm_repo_pre }} |
| Next major version prereleases | `next-major` | {{ helm_repo_next }} |
| Beta releases | `beta` | {{ helm_repo_beta }} |
| Alpha releases | `alpha` | {{ helm_repo_alpha }} |

!!! note
    The `devel` release channel has been deprecated and will no longer be used going forwards.

    This was only used prior to the initial release of version `1.0.0` of the Helm Chart

We recommend using the `stable` channel so that you can deploy officially supported releases of the Smile CDR Helm Chart.

If you wish to preview upcoming features that are not yet available in a currently supported Helm Chart version in the `stable` channel, then you may use prerelease versions from another release channel.

!!! warning
    When using release channels other than `stable`, there may be unexpected breaking changes or regressions between pre release or beta versions.

## Configuring Release Channels

The mechanism for configuring the release channel depends on which tooling you are using to deploy the Helm Chart.

=== "Using the `helm` Command"

    If you are deploying using the `helm` command, you can add multiple Helm repos to your local Helm installation like so:

    Add the `stable` repo
    ```shell
    $ helm repo add smiledh-stable {{ helm_repo_stable }}
    $ helm repo update
    ```

    Add the `pre-release` repo
    ```shell
    $ helm repo add smiledh-pre {{ helm_repo_pre }}
    $ helm repo update
    ```

=== "Using the `helm` Terraform Provider"

    If you are using the Terraform [Helm provider](https://registry.terraform.io/providers/hashicorp/helm/), the process is slightly different as there is no concept of adding the repository to your local installation as there is with the `helm` command method.

    <!-- This means that is it not possible to have multiple channels available simultaneously as you would above. -->

    Instead, you specify the appropriate channel in your [`helm_release`](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) resource:

    Use the `stable` repo
    ```hcl
    resource "helm_release" "example" {
      name       = "my-smilecdr-release"
      repository = "{{ helm_repo_stable }}"
      chart      = "smilecdr"
      version    = "{{ current_helm_version }}"
    }
    ```

    Use the `pre-release` repo
    ```hcl
    resource "helm_release" "example" {
      name       = "my-smilecdr-release"
      repository = "{{ helm_repo_pre }}"
      chart      = "smilecdr"
      devel      = true
    }
    ```
    !!! warning
        By using `devel = true`, this will install the latest version from the `pre` channel unless you explicitly set `version`
        This could result in unexpected breaking changes being introduced.

        It is recommended to always specify a version of the Helm Chart that you wish to install.

## Switching Release Channels

=== "Using the `helm` Command"
    If you have previously added the repository for the `devel` channel to your local Helm installation, you should remove it and switch to use the `stable` channel instead.

    Remove the existing repository for the `devel` channel and add the repository for the `stable` channel.

    ```shell
    $ helm repo remove smiledh # <-- Or whatever you previously named the repo locally
    $ helm repo add smiledh {{ helm_repo_stable }}
    $ helm repo update
    ```

    You can also add additional release channels as additional local repositories. To do this, you would run the `helm repo add` command for each repository, using different aliases as shown in the examples further up this page.

=== "Using the `helm` Terraform Provider"
    If you are using the Terraform `helm_provider` as explained above, switching from the `devel` channel to the `stable` channel is done by replacing:

    ```
        repository = "{{ helm_repo_devel }}"
        devel      = true
    ```

    with

    ```
        repository = "{{ helm_repo_stable }}"
        version    = "{{ current_helm_version }}"
    ```

    !!! note
        The `devel` option has no effect on the `stable` branch and need not be used, as there are no pre release or beta versions published there.

## Choosing The Helm Chart Version

It is advisable to explicitly set the `version` rather than allowing Helm to automatically use the latest version. This will help reduce the chances of accidental upgrades to new versions.
