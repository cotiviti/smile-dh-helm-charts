# DESIGN.md

## Overview

This Helm chart uses a non-traditional architecture compared to many simpler charts that rely primarily on direct variable substitution and straightforward conditional templating. Instead, it constructs a rich, nested internal representation of the intended deployment architecture before generating actual Kubernetes resources. This design was driven by the need to support complex configuration, platform variability, and dynamic resource generation — all within the constraints of Helm’s Go templating engine.

This document provides new developers with insight into the design philosophy, structure, and rationale behind the chart. It aims to bridge the gap for those coming from simpler Helm charts and to prepare you for working safely within this system.

---

## Key Design Principles

### 1. **Internal Deployment Object Model**

Rather than rendering values directly into Kubernetes manifests, the chart builds a detailed object tree (in Go template logic) that represents the deployment in abstract terms. This object tree:

- Encapsulates high-level configuration decisions
- Encodes relationships between components
- Supports conditional generation of resources

For example, a helper function might build a list of service objects, conditionally include optional sidecars, or determine storage volumes — all before a single resource manifest is rendered.

This results in a powerful abstraction, but makes the chart harder to follow at a glance.

### 2. **Centralized Helper Logic**

A majority of the deployment logic resides in various helper template files (e.g. `_scdr-misc-helpers.tpl`), where the internal data structures are assembled. These helpers do much more than render simple strings (as is typical in many Helm Charts). Instead, they build lists, maps, and nested objects using various Go templating constructs.

Templates for actual resources then "unpack" this internal model, looping over or conditionally rendering its components.

### 3. **Dynamic Resource Count and Shape**

The chart often generates a variable number of resources based on configuration. This includes, but is not limited to:

- Multiple `Deployment`, `Service`, `ConfigMap` or `Ingress` resources
- Conditional `ServiceAccount`, `ConfigMap`, or `Ingress` definitions
- Different routing or volume configurations depending on platform and feature set

This makes the logic more abstract and harder to trace linearly.

### 4. **Multi-Platform Support Encapsulation**

Rather than duplicating templates for each platform (EKS, AKS, GKE, OpenShift), platform-specific logic is embedded within the internal object model.

For example:

- A helper might set `Ingress` resource annotations based on `ingresses.default.type: aws-lbc-alb` 
- Another might create differently structured `SecretProviderClass` resources depending on the Secret Store CSI Provider being used.

This approach minimizes duplication, but adds conditional complexity deep within the logic.

---

## Developer Implications

### - **Debugging and Tracing Logic**

The logic flow can be hard to follow because the meaningful work often happens inside helpers, not the templates themselves. You may need to:

- Trace how values are constructed in the helper template files
- Understand how one helper's output feeds another
- Track platform flags and where they're evaluated

### - **Modifying or Extending the Chart**

Simple-looking changes may require updates to multiple helpers and their consumers. Adding a new feature may involve:

- Adding flags or config branches to internal object builders
- Adjusting multiple resource templates to consume new object structure

### - **Regression Risk and Testing**

Because internal objects drive output across many files, a small logic change can affect many manifests. A regression testing framework exists to catch unexpected diffs in generated output, but careful review is still needed.

---

## Summary

This chart’s design pushes Helm beyond simple templating, enabling support for complex, highly configurable, and platform-portable deployments. However, this power comes with increased complexity, and developers must be familiar with its object-centric architecture to work safely and effectively.

Approach changes thoughtfully, test thoroughly, and don’t hesitate to spend time understanding the structure before diving into feature development or refactoring.
