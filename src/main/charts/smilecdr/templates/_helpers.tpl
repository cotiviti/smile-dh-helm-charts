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
Generate a consistent resource name from a provided name
Based on "smilecdr.fullname" above, but used for generating different resources with a consistent
schema for the prefix.

Unlike the above template, this needs a dict object to be passed in, that contains the following:
rootCTX: - The root context (Required for access to Release name, chart name and values)
name: - The name of the resource which you wish to prepend a consistent resource name prefix
*/}}
{{- define "smilecdr.resourceName" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $releaseName := $rootCTX.Release.Name -}}
  {{- $fullnameOverride := $rootCTX.Values.fullnameOverride -}}
  {{- $chartName := default $rootCTX.Chart.Name $rootCTX.Values.nameOverride -}}
  {{- $name := get . "name" -}}
  {{- /* https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#rfc-1035-label-names */ -}}
  {{- /* Sub from 62 instead of 63 as we add a hyphen back */ -}}
  {{- $maxPrefixLength := sub (len $name) 63 | int -}}
  {{- $resourceNamePrefix := "" -}}
  {{- if $fullnameOverride -}}
    {{- /* If fullnameOverride is being used, then we will use this for all resource name prefixes */ -}}
    {{- $resourceNamePrefix = $fullnameOverride| trimSuffix "-" | trunc $maxPrefixLength -}}
  {{- else -}}
    {{- if contains $chartName $releaseName -}}
      {{- /* If the release name contains the chart name, no need to include the chart name */ -}}
      {{- $resourceNamePrefix = $releaseName | trimSuffix "-" | trunc $maxPrefixLength -}}
    {{- else -}}
      {{- /* Include the release name and chart name in the resource name prefix */ -}}
      {{- $resourceNamePrefix = printf "%s-%s" $releaseName $chartName | trimSuffix "-" | trunc $maxPrefixLength -}}
    {{- end -}}
  {{- end -}}
  {{- lower (printf "%s-%s" $resourceNamePrefix $name) -}}
{{- end -}}

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
