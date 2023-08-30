{{/*
Expand the name of the chart.
*/}}
{{- define "smilecdr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "smilecdr.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "smilecdr.chart" -}}
  {{- $chartVersion := printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
  {{- if .Values.unitTesting -}}
    {{- print "No Chart Version - Unit Testing" -}}
  {{- else -}}
    {{- $chartVersion -}}
  {{- end -}}
{{- end }}

{{/*
Determine Smile CDR application version.
*/}}
{{- define "smilecdr.appVersion" -}}
  {{- $cdrVersion := coalesce .Values.image.tag .Chart.AppVersion -}}
  {{- if .Values.unitTesting -}}
    {{- $cdrVersion = "No App Version - Unit Testing" -}}
  {{- end -}}
  {{- $cdrVersion -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "smilecdr.labels" -}}
helm.sh/chart: {{ include "smilecdr.chart" . }}
{{ include "smilecdr.selectorLabels" . }}
app.kubernetes.io/version: {{ include "smilecdr.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels -}}
{{ with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end -}}
{{- end }}



{{/*
Selector labels
*/}}
{{- define "smilecdr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "smilecdr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "smilecdr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "smilecdr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
