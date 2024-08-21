# Release Channels

The Smile CDR Helm Charts are available in 2 release channels.

| Release Type | Channel Name | Helm Chart Repo |
| ------------ | ------------ | --------------- |
| Official | `STABLE` | {{ helm_repo_stable }} |
| Pre release | `DEVEL` | {{ helm_repo_devel }} |
| Beta release | `DEVEL` | {{ helm_repo_devel }} |

We recommend using the `STABLE` channel so that you can deploy officially supported releases of the Smile CDR Helm Chart.

If you wish to preview upcoming features that are not yet available in a currently supported Helm Chart version in the `STABLE` channel, then you may use pre releases or beta releases from the `DEVEL` channel.

>**Note:** When using the `DEVEL` channel, there may be unexpected breaking changes or regressions between pre release or beta versions.

## Configuring Release Channels

The mechanism for configuring the release channel depends on which tooling you are using to deploy the Helm Chart.

=== "Using the `helm` Command"

    If you are deploying using the `helm` command, you will be adding the Helm repo to your local Helm installation like so:

    Add the `STABLE` repo
    ```shell
    $ helm repo add smiledh-stable {{ helm_repo_stable }}
    $ helm repo update
    ```

    Add the `DEVEL` repo
    ```shell
    $ helm repo add smiledh-devel {{ helm_repo_devel }}
    $ helm repo update
    ```

=== "Using the `helm` Terraform Provider"

    If you are using the Terraform [Helm provider](https://registry.terraform.io/providers/hashicorp/helm/), the process is slightly different as there is no concept of adding the repository to your local installation as there is with the `helm` command method.

    <!-- This means that is it not possible to have both channels available simultaneously as you would above. -->

    Instead, you specify the appropriate channel in your [`helm_release`](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) resource:

    Use the `STABLE` repo
    ```hcl
    resource "helm_release" "example" {
      name       = "my-smilecdr-release"
      repository = "{{ helm_repo_stable }}"
      chart      = "smilecdr"
      version    = "{{ current_helm_version }}"
    }
    ```

    Use the `DEVEL` repo
    ```hcl
    resource "helm_release" "example" {
      name       = "my-smilecdr-release"
      repository = "{{ helm_repo_devel }}"
      chart      = "smilecdr"
      devel      = true
    }
    ```
    !!! warning
        By using `devel = true`, this will install the latest version from the `DEVEL` channel unless you explicitly set `version`
        This could result in unpredictable behaviour by installing a beta version rather than a pre release version.

        It is recommended to always specify a version of the Helm Chart that you wish to install.

## Switching Release Channels

=== "Using the `helm` Command"
    If you have added the repository for the `DEVEL` channel to your local Helm installation, you can switch to use the `STABLE` channel in two ways.

    1. Add the `STABLE` channel as an additional local repository. To do this, you would run the `helm repo add` command for each repository, using different aliases as shown in the examples further up this page.
    2. Remove the existing repository for the `DEVEL` channel and add the repository for the `STABLE` channel. If you have used a local repository alias that does not indicate which release channel it represents, this option may work better for you.

    ```shell
    $ helm repo remove smiledh # <-- Or whatever you named the repo locally
    $ helm repo add smiledh {{ helm_repo_stable }}
    $ helm repo update
    ```

=== "Using the `helm` Terraform Provider"
    If you are using the Terraform `helm_provider` as explained above, switching from the `DEVEL` channel to the `STABLE` channel is done by replacing:

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
        The `devel` option has no effect on the `STABLE` branch and need not be used, as there are no pre release or beta versions published there.

## Choosing The Helm Chart Version

It is advisable to explicitly set the `version` rather than allowing Helm to automatically use the latest version. This will help reduce the chances of accidental upgrades to new versions.
