# Custom Environment Configuration
Sometimes you may have custom components in your Smile CDR deployment that need to have configurations provided to them.

In Smile CDR, this can be done one in of two ways.

* Java System Property Substitution
* System Environment Variable Substitution

You can read more about these methods in the official Smile CDR documentation [here](https://smilecdr.com/docs/installation/installing_smile_cdr.html#variable-substitution)

Currently, this Helm Chart only supports using the second mechanism - ***System Environment Variable Substitution***


## Passing Extra Environment Variables

In order to configure extra environment variables into the pod, use the `ExtraEnvVars` entry in your values file as follows:

```yaml
extraEnvVars:
- name: MYENVVARNAME
  value: my-env-var-value
- name: MYOTHERENVVARNAME
  value: my-other-env-var-value
```

This is a list of objects that follow the same `env` schema as the Kubernetes `podSpec.containers` [See here](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables)

>**Note:** Although it is possible to use this to add secrets using `env.valueFrom.secretKeyRef`, it's recommended to use one of the existing mechanisms if you wish to pass in secret data to your pod. See the [Secrets](../secrets.md) section for more info on this.

## Multi-node configuration
If deploying Smile CDR in a multi-node configuration, you may wish to have different environment variables for the different CDR Nodes.

>**Note:** For more details on how to deploy Smile CDR with multi-node configurations, please refer to the [CDR Nodes](./cdrnode.md) section.

```yaml
cdrNodes:
  node1:
    extraEnvVars:
    - name: MYENVVARNAME
      value: my-node1-env-var-value
  node2:
    extraEnvVars:
    - name: MYENVVARNAME
      value: my-node2-env-var-value
  node3:
    extraEnvVars:
    - name: MYENVVARNAME
      value: my-node3-env-var-value
    - name: GLOBALENVVARNAME
      value: node3-overriden-global-value

extraEnvVars:
- name: GLOBALENVVARNAME
  value: my-global-env-var-value

```

In the above configuration example:

* Each node gets its own set of extra environment variables.
* Each node gets the `GLOBALENVVARNAME` variable set to `my-global-env-var-value` except...
* Node3 has overriden the `GLOBALENVVARNAME` variable to `node3-overriden-global-value`

This allows for flexible configuration of extra environment variables in any Smile CDR configuration.