{{/*
Expand the name of the chart.
*/}}
{{- define "pmp.name" -}}
{{- if .Chart.Name }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Chart.name -}}
{{- default .Chart.name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}
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
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "pmp.chart.old" -}}
{{- if .Chart.Name -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- else if .Chart.name -}}
  {{- printf "%s-%s" .Chart.name .Chart.version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pmp.labels" -}}
  {{- $labels := dict -}}
  {{- $_ := set $labels "helm.sh/chart" (include "pmp.chart" .) -}}
  {{- $_ := set $labels "app.kubernetes.io/version" (toString .Chart.AppVersion) -}}
  {{- $_ := set $labels "app.kubernetes.io/managed-by" .Release.Service -}}
  {{- $labels = merge $labels (include "pmp.selectorLabels" . | fromYaml) -}}
  {{- $labels | toYaml -}}
{{- end -}}
{{- /* define "pmp.labels.old" -}}
{{ include "pmp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- else if .Chart.appVersion }}
app.kubernetes.io/version: {{ .Chart.appVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end */ -}}

{{/*
Selector labels
*/}}
{{- /* define "pmp.selectorLabels.old" -}}
app.kubernetes.io/name: {{ include "pmp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end */ -}}
{{- define "pmp.selectorLabels" -}}
  {{- $selectorLabels := dict -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/name" (include "pmp.name" .) -}}
  {{- $_ := set $selectorLabels "app.kubernetes.io/instance" .Release.Name -}}
  {{- $selectorLabels | toYaml -}}
{{- end -}}

{{/*
Create the name of the service account to use for pmp
*/}}
{{- /* define "pmp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pmp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "pmp-default" .Values.serviceAccount.name }}
{{- end }}
{{- end */ -}}

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
