# Configure Helm Repository:

Before you can use the Smile Digital Health Helm Charts, you need to configure your
deployment tool to point to the repository where the charts are hosted.

In this Quickstart, we will use the native `helm` command, but you may wish to
deploy using alternative tooling in your environment. Please check the User Guide
for more info on this.

## Add repository
Add the repository like so.

```shell
$ helm repo add smiledh-stable {{ helm_repo_stable }}
$ helm repo update
```

> **Note** It is also possible to run the `helm install` command by pointing directly to the repository.
In this case, there is no need to run the `helm repo` commands above.
