{{/*
Define extra details for PMP Member Portal
*/}}

{{/*
Helper to define per-component merged context. Used for passing to templates
that work in global or component context.
Returns an object that looks like the global $ context, but with the component
values merged into $.Values

Use this template as follows:
{{- $componentContext := include "component.getMergedContext" (dict "componentName" $componentName "componentObject" $componentObject "globalObject" $) | fromYaml -}}

NOTE: $.Chart is a `struct` and not a `dict` as you would expect. Unfortunately the uppercased values (e.g. $.Chart.Name) get changed to lower case (so $.Chart.name)
      when converting with toYaml or toJson. This means any templates that get Chart values using this modified context will need to try both the upper-cased and the
      lower case version.

*/}}
{{- /* define "component.getMergedContext" -}}
    {{- $mergedValues := mergeOverwrite (deepCopy .globalObject.Values) (deepCopy .componentObject) -}}
    {{- $componentContext := (dict "componentName" .componentName "Chart" (deepCopy .globalObject.Chart) "Release" (deepCopy .globalObject.Release) "Values" $mergedValues) -}}
    {{- $componentContext | toYaml -}}
{{- end */ -}}

{{- define "pmp.components" -}}
  {{- $components := dict -}}
  {{- $rootCTX := . -}}
  {{- $globalValues := deepCopy .Values -}}
  {{- range $theComponentName, $theComponentSpec := $globalValues.components -}}
    {{- if not (hasKey $theComponentSpec "enabled" ) -}}
      {{- fail (printf "Component %s does not have `enabled` key set" $theComponentName) -}}
    {{- end -}}
    {{- if $theComponentSpec.enabled -}}
      {{- /* $parsedComponentValues := mustMergeOverwrite (deepCopy (omit $globalValues "components")) (deepCopy (omit $theComponentSpec "ingress")) */ -}}
      {{- /* $parsedComponentValues := mustMergeOverwrite (deepCopy (omit $globalValues "components")) (deepCopy $theComponentSpec ) */ -}}
      {{- /* TODO: Some refactoring on how global `components` are referenced. Having them duplicated like this seems excessive.
          Instead, the updated context being passed about should have access to the default root context, maybe... */ -}}
      {{- $parsedComponentValues := mustMergeOverwrite (deepCopy $globalValues) (deepCopy $theComponentSpec ) -}}

      {{- $_ := set $parsedComponentValues "componentName" $theComponentName -}}
      {{- $_ := set $parsedComponentValues "releaseName" $.Release.Name -}}

      {{- /* Set PMP component specific labels */ -}}
      {{- $componentLabels := include "pmp.labels" $rootCTX | fromYaml -}}
      {{- $_ := set $componentLabels "app.kubernetes.io/component" $theComponentName -}}

      {{- $componentSelectorLabels := include "pmp.selectorLabels" $rootCTX | fromYaml -}}
      {{- $_ := set $componentSelectorLabels "app.kubernetes.io/component" $theComponentName -}}
      
      {{- $_ := set $parsedComponentValues "componentLabels" $componentLabels -}}
      {{- $_ := set $parsedComponentValues "componentSelectorLabels" $componentSelectorLabels -}}

      {{- /* Note: Only doing the deepCopy on the root ctx.
          $parsedComponentValues is merged as a reference, so anything updated
          will be available in the context for further includes */ -}}
      {{- $componentHelperCTX := mustMergeOverwrite (deepCopy (omit $rootCTX "Values")) (dict "Values" $parsedComponentValues) -}}

      {{- $_ := set $parsedComponentValues "fullName" (include "component.fullname" $componentHelperCTX) -}}

      {{- $_ := set $parsedComponentValues "serviceAccountName" (include "component.serviceAccountName" $componentHelperCTX) -}}

      {{- $_ := set $parsedComponentValues "imagePullSecretsList" (include "sdhCommon.imagePullSecretsList" $componentHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedComponentValues "envVars" (include "component.envVars" $componentHelperCTX | fromYamlArray) -}}

      {{- $_ := set $parsedComponentValues "k8sSecretObjects" (include "sdhCommon.secrets.k8sSecretObjects" $componentHelperCTX | fromYamlArray) -}}

      {{- $sscsiSpec := dict -}}
      {{- $_ := set $sscsiSpec "enabled" (include "sdhCommon.sscsi.enabled" $componentHelperCTX) -}}
      {{- /* fail (printf "Hiiiii%s" (include "sdhCommon.sscsi.enabled" $componentHelperCTX)) */ -}}
      {{- $_ := set $sscsiSpec "secretProviderClassName" (include "sdhCommon.sscsi.secretProviderClassName" $componentHelperCTX) -}}
      {{- $_ := set $sscsiSpec "objects" (include "sdhCommon.sscsi.objects" $componentHelperCTX | fromYamlArray) -}}
      {{- $_ := set $sscsiSpec "syncedSecrets" (include "sdhCommon.sscsi.syncedSecrets" $componentHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedComponentValues "sscsi" $sscsiSpec -}}
      
      {{- $_ := set $components $theComponentName $parsedComponentValues -}}

    {{- end -}}
  {{- end -}}
  {{- $components | toYaml -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "component.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- printf "%s-%s" (.Values.fullnameOverride | trunc 63 | trimSuffix "-") .Values.resourceSuffix -}}
  {{- else -}}
    {{- $name := "" -}}
    {{- if .Chart.Name -}}
      {{- $name = default .Chart.Name .Values.nameOverride -}}
    {{- else if .Chart.name -}}
      {{- $name = default .Chart.name .Values.nameOverride -}}
    {{- end -}}
    {{- if contains $name .Release.Name -}}
      {{- printf "%s-%s" (.Release.Name | trunc 63 | trimSuffix "-") .Values.resourceSuffix -}}
    {{- else -}}
      {{- printf "%s-%s-%s" .Release.Name ($name | trunc 63 | trimSuffix "-") .Values.resourceSuffix -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- /* define "component.labels" -}}
  {{- $labels := dict -}}
  {{- $_ := set $labels "helm.sh/chart" include "pmp.chart" . -}}
  {{- $_ := set $labels "app.kubernetes.io/version" .chartAppVersion | quote -}}
  {{- $_ := set $labels "app.kubernetes.io/managed-by" .releaseService -}}
  {{- $labels = merge $labels (include "component.selectorLabels" . | fromYaml) -}}
  {{- $labels | toYaml -}}
{{- end */ -}}

{{- /*
Selector labels
*/ -}}
{{- /* define "component.selectorLabels" -}}
  {{- $selectorLabels := dict -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/name" include "pmp.name" . -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/component" .componentName -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/instance" .releaseName -}}
  {{- $selectorLabels | toYaml -}}
{{- end */ -}}

{{/*
Create the name of the service account to use for memberPortal
*/}}
{{- define "component.serviceAccountName" -}}
  {{- if (.Values.serviceAccount).create -}}
    {{- default (include "component.fullname" .) .Values.serviceAccount.name -}}
  {{- else -}}
    {{- "default" -}}
  {{- end -}}
{{- end -}}
