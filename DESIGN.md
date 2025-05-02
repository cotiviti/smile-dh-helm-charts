## Internal Architecture and Contribution Guide

This document provides implementation details and contributor guidance for the Helm chart described in the high-level `DESIGN-SUMMARY.md`. It expands on structural patterns, helper conventions, platform logic, and testing strategies that underpin the chart's dynamic rendering model.

---

### Smile CDR Cluster and Node Architecture

The chart supports deployment of a Smile CDR "Cluster", which consists of one or more independently defined `cdrNodes`. Each node is a separately configured `Deployment` but shares certain cluster-wide components. This structure allows flexible multi-node architectures while maintaining a single coordinated Helm release.

#### Key Concepts:

* **cdrNodes**: Each item under `cdrNodes` represents a separate Smile CDR node, which results in a separate `Deployment` resource.
* **Shared Configuration**: Some components (e.g., file-based `ConfigMaps`, TLS issuers, shared labels) are configured once but used by all nodes.
* **Top-Level Helper**: The main entry point for building the deployment structure is the `smilecdr.cdrNodes` helper in `_scdr-cdr-node-helpers.tpl`.

This helper builds the internal object representation for each node, which is later unpacked by templates to render multiple `Deployment` resources.

#### Example (Simplified `cdrNodes` Helm Values Input):

```yaml
cdrNodes:
  masterdev:
    name: Masterdev
    enabled: true
    modules:
      ...
```

#### Flow Summary:

1. The root helper `smilecdr.cdrNodes` constructs a list of node definitions based on the provided values file.
2. Each node’s structure includes metadata, volumes, initcontainers, containers, sidecars, services, ingress rules, configMaps, secret configurations and other runtime details.
3. Many resource templates iterate over this structure to render deployments dynamically.

This flexible model is what enables the Helm chart to support arbitrary node configurations within a single coordinated deployment.

---

### Internal Object Model: Structural Guidelines

The chart builds a structured internal object model to represent deployment decisions before rendering Kubernetes manifests. This model includes structured keys for components, features, and platform-specific logic.

#### smilecdr.cdrNodes data structure (Pseudo-Structure):

> Shown in a yaml format simply to help visualise the structure.

```yaml
smilecdr.cdrNodes:
  <node-name>:
    cdrNodeName:
    propertiesData:
    configMapName:
    configMapResourceSuffix:
    resourceSuffix:
    cdrNodeId:
    cdrNodeLabels:
    cdrNodeSelectorLabels:
    deploymentAnnotations:
    podAnnotations:
    kafka:
    volumes:
    volumeMounts:
    mappedFiles:
    imagePullSecretsList:
    serviceAccountName:
    initContainers:
    certificates:
    envVars:
    services:
    containerPorts:
    startupProbe:
    readinessProbe:
    livenessProbe:
    topologySpreadConstraints:
```

Each of the above per-node value is in-turn derived from additional helper templates. Review the code to determine the source template and follow the code-path.

For example, if we wish to see where `initContainers` is defined, we search for it in  `_scdr-cdr-node-helpers.tpl` to see the following:

```yaml
{{- $_ := set $parsedNodeValues "initContainers" (include "smilecdr.initContainers" $cdrNodeHelperCTX | fromYamlArray) -}}
```

From here, we see that it's included from the `smilecdr.initContainers` helper, which is included in `_scdr-misc-helpers.tpl`.

If you continue to follow, you will then find that `smilecdr.initContainers` is just a helper that concatenates lists defined in other templates, such as `smilecdr.initFileContainers` and `smilecdr.initMigrateContainers`.

---

### Passing Data Between Templates

As the GO Templating language is essentially a textual templating engine, any output from one template is passed into futher templates as text. In order convert the internal objects to a format suitable for passing and futher consumption in parent templates, the data must first be converted to a text format.

#### Encoding template output

To achieve this, the templates make extensive use of the toYaml function. For Example:

```gotpl
{{- define "smilecdr.cdrNodes" -}}
  ...
  {{- $cdrNodes | toYaml -}}
{{- end -}}
```

#### Decoding template output

When using the output from a template such as `smilecdr.cdrNodes` above, you need to reverse the process.

For example, to include and iterate over all the cdrNodes, you would:

```
{{- range $theCdrNodeName, $theCdrNodeCtx := include "smilecdr.cdrNodes" . | fromYaml -}}
  {{- $theCdrNodeSpec := $theCdrNodeCtx.Values -}}
apiVersion: apps/v1
kind: Deployment
...
---
{{ end }}
```

---


### Common Pitfalls

* Embedding logic in resource templates instead of helpers
* Mutating `.Values` during template rendering
* Copy-pasting platform logic instead of using centralized helpers

---

### Contributor Workflow

1. Start in a helper: create or modify a builder
2. Update the internal object structure
3. Reference object structure in templates
4. Add regression test inputs and outputs
5. Submit PR with reasoning and validation

---

### Summary

This Helm chart emphasizes structured abstraction over direct rendering. Working with it means embracing helper-driven logic, central configuration models, and robust testing discipline. These conventions enable flexibility while managing complexity — essential for scalable, multi-platform deployments.
