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
{{- define "component.getMergedContext" -}}
    {{- $mergedValues := mergeOverwrite (deepCopy .globalObject.Values) (deepCopy .componentObject) -}}
    {{- $componentContext := (dict "componentName" .componentName "Chart" (deepCopy .globalObject.Chart) "Release" (deepCopy .globalObject.Release) "Values" $mergedValues) -}}
    {{- $componentContext | toYaml -}}
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
{{- define "component.labels" -}}
helm.sh/chart: {{ include "pmp.chart" . }}
{{ include "component.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- else if .Chart.appVersion }}
app.kubernetes.io/version: {{ .Chart.appVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "component.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pmp.name" . }}
app.kubernetes.io/component: {{ .componentName }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for memberPortal
*/}}
{{- define "component.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "component.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- print "default" }}
{{- end }}
{{- end }}
