{{/*
Expand the name of the chart.
*/}}
{{- define "pmp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pmp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- /*
Create chart name and version as used by the chart label.
*/ -}}
{{- define "pmp.chart" -}}
  {{- $chartVersion := printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
  {{- if .Values.unitTesting -}}
    {{- print "No Chart Version - Unit Testing" -}}
  {{- else -}}
    {{- $chartVersion -}}
  {{- end -}}
{{- end }}

{{/*
Determine PMP/P2P application version.
*/}}
{{- define "pmp.appVersion" -}}
  {{- $pmpVersion := coalesce (.Values.image).tag .Chart.AppVersion -}}
  {{- if .Values.unitTesting -}}
    {{- $pmpVersion = "No App Version - Unit Testing" -}}
  {{- end -}}
  {{- $pmpVersion -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "pmp.labels" -}}
  {{- $labels := dict -}}
  {{- $_ := set $labels "helm.sh/chart" (include "pmp.chart" .) -}}
  {{- $_ := set $labels "app.kubernetes.io/version" (include "pmp.appVersion" .) -}}
  {{- $_ := set $labels "app.kubernetes.io/managed-by" .Release.Service -}}
  {{- $labels = merge $labels (include "pmp.selectorLabels" . | fromYaml) -}}
  {{- $labels | toYaml -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "pmp.selectorLabels" -}}
  {{- $selectorLabels := dict -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/name" (include "pmp.name" .) -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/instance" .Release.Name -}}
  {{- $selectorLabels | toYaml -}}
{{- end -}}

{{/*
Generate a suffix that represents the SHA256 hash of the provided
data if autoDeploy is enabled. Used for naming configMaps.
You must pass in a map with the root `Values` map and `data` to be hashed.
*/}}
{{- define "pmp.getConfigMapNameHashSuffix" -}}
  {{- if (.Values.autoDeploy) -}}
    {{- printf "-%s" (trunc 40 (sha256sum (toYaml .data))) -}}
  {{- end -}}
{{- end -}}

{{/*
Generate a normalised name that can be used in Kubernetes resources.
Upper case characters are disallowed, so will me made lower case.
Period (`.`) and underscore (`_`) characters are disallowed so will
be replaced with a hyphen (`-`).
*/}}
{{- define "pmp.getNormalisedResourceName" -}}
  {{- . | replace "." "-" | replace "_" "-" | lower -}}
{{- end -}}

{{- $_ := set .Values "renderedfiles" (($.Files.Glob "authcallback.js").AsConfig ) -}}
