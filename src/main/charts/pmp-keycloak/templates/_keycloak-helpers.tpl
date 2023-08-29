{{/*
Define extra details for Keycloak
*/}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "keycloak.chart" -}}
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
{{- define "keycloak.appVersion" -}}
  {{- $keycloakVersion := coalesce .Values.image.tag .Chart.AppVersion -}}
  {{- if .Values.unitTesting -}}
    {{- $keycloakVersion = "No App Version - Unit Testing" -}}
  {{- end -}}
  {{- $keycloakVersion -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "keycloak.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}-keycloak
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}-keycloak
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}-keycloak
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/version: {{ include "keycloak.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: keycloak
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Define Keycloak environment variables

Note:
This template simply collates the environment variables defined elsewhere to
provide a single entry point.
*/}}
{{- define "keycloak.envVars" -}}
  {{- $envVars := list -}}
  {{- /* Include DB env vars */ -}}
  {{- $envVars = concat $envVars (include "sdhCommon.dbEnvVars" . | fromYamlArray ) -}}
  {{- /* Include extra secrets env vars */ -}}
  {{- $envVars = concat $envVars (include "sdhCommon.extraSecretsEnvVars" . | fromYamlArray ) -}}
  {{- if .Values.ingress.enabled -}}
    {{- $contextRoot := include "keycloak.contextRoot" . -}}
    {{- $envVars = append $envVars (dict "name" "KC_HOSTNAME" "value" (index .Values.ingress.hosts 0).host) -}}
    {{- $envVars = append $envVars (dict "name" "KC_PROXY" "value" "edge" ) -}}
    {{- $envVars = append $envVars (dict "name" "KC_DB" "value" "postgres" ) -}}
    {{- $envVars = append $envVars (dict "name" "KC_HTTP_RELATIVE_PATH" "value" $contextRoot) -}}
  {{- end -}}
  {{- /* Include global extra env vars */ -}}
  {{- $envVars = concat $envVars .Values.extraEnvVars -}}
  {{- $envVars | toYaml -}}
{{- end -}}

{{/*
Create the name of the service account to use for keycloak
*/}}
{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "keycloak-default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define Keycloak DB Type
*/}}
{{- define "keycloak.dbType" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "postgres" .Values.database.crunchypgo.type -}}
{{- else if and (.Values.database.external).enabled -}}
{{- default "postgres" (.Values.database.external).type -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Keycloak DB Port
*/}}
{{- define "keycloak.dbPort" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "5432" .Values.database.crunchypgo.port -}}
{{- else if and (.Values.database.external).enabled (eq (.Values.database.external).dbType "postgres" ) -}}
{{- default "5432" (.Values.database.external).port -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Keycloak DB secret
*/}}
{{- define "keycloak.dbSecretName" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- $crunchyUserName := default "keycloak" (.Values.database.crunchypgo).userName -}}
{{- printf "%s-pg-pguser-%s" .Release.Name $crunchyUserName }}
{{- else if and (.Values.database.external).enabled -}}
{{- default "changemepls" (.Values.database.external).secretName -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Keycloak context root
*/}}
{{- define "keycloak.contextRoot" -}}
  {{- if and .Values.ingress.enabled -}}
    {{- with (index (index .Values.ingress.hosts 0).paths 0).path -}}
      {{- . -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
