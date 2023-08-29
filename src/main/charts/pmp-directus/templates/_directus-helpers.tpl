{{/*
Define extra details for Directus
*/}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "directus.chart" -}}
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
{{- define "directus.appVersion" -}}
  {{- $directusVersion := coalesce .Values.image.tag .Chart.AppVersion -}}
  {{- if .Values.unitTesting -}}
    {{- $directusVersion = "No App Version - Unit Testing" -}}
  {{- end -}}
  {{- $directusVersion -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "directus.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}-directus
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}-directus
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}-directus
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "directus.labels" -}}
helm.sh/chart: {{ include "directus.chart" . }}
{{ include "directus.selectorLabels" . }}
app.kubernetes.io/version: {{ include "directus.appVersion" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "directus.selectorLabels" -}}
app.kubernetes.io/name: directus
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Define Directus environment variables

Note:
This template simply collates the environment variables defined elsewhere to
provide a single entry point.
*/}}
{{- define "directus.envVars" -}}
  {{- $envVars := list -}}
  {{- /* Include DB env vars */ -}}
  {{- $envVars = concat $envVars (include "sdhCommon.dbEnvVars" . | fromYamlArray ) -}}
  {{- /* Include extra secrets env vars */ -}}
  {{- $envVars = concat $envVars (include "sdhCommon.extraSecretsEnvVars" . | fromYamlArray ) -}}
  {{- if .Values.ingress.enabled -}}
    {{- /* $envVars = append $envVars (dict "name" "PUBLIC_URL" "value" printf "http%s://%s" (ternary "s" "" .Values.ingress.tls) (index .Values.ingress.hosts 0).host ) */ -}}
    {{- $proto := ternary (print "https") (print "http") (hasKey .Values.ingress "tls") -}}
    {{- $envVars = append $envVars (dict "name" "PUBLIC_URL" "value" (printf "%s://%s" $proto (index .Values.ingress.hosts 0).host )) -}}
  {{- end -}}
  {{- $envVars = append $envVars (dict "name" "DB_CLIENT" "value" (include "directus.dbType" .)) -}}
  {{- $envVars = append $envVars (dict "name" "PMP_IDP_SIGNUP_LINK" "value" .Values.idpSignupLink) -}}
  {{- $envVars = append $envVars (dict "name" "CORS_ORIGIN" "value" (include "directus.corsOrigins" .)) -}}
  {{- $envVars = concat $envVars (include "directus.storageEnvVars" . | fromYamlArray ) -}}
  {{- /* Include global extra env vars */ -}}
  {{- $envVars = concat $envVars .Values.extraEnvVars -}}
  {{- $envVars | toYaml -}}
{{- end -}}

{{/*
Create the name of the service account to use for directus
*/}}
{{- define "directus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "directus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "directus-default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define Directus DB Type
*/}}
{{- define "directus.dbType" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "postgres" .Values.database.crunchypgo.type -}}
{{- else if and (.Values.database.external).enabled -}}
{{- default "postgres" (.Values.database.external).type -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Directus DB Port
*/}}
{{- define "directus.dbPort" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "5432" .Values.database.crunchypgo.port -}}
{{- else if and (.Values.database.external).enabled (eq (.Values.database.external).dbType "postgres" ) -}}
{{- default "5432" (.Values.database.external).port -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Directus DB secret
*/}}
{{- define "directus.dbSecretName" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- $crunchyUserName := default "directus" (.Values.database.crunchypgo).userName -}}
{{- printf "%s-pg-pguser-%s" .Release.Name $crunchyUserName }}
{{- else if and (.Values.database.external).enabled -}}
{{- default "changemepls" (.Values.database.external).secretName -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Directus Redis Env if included Redis is used
*/}}
{{- define "directus.redisEnv" -}}
{{- if .Values.redis.enabled -}}
- name: CACHE_STORE
  value: "redis"
- name: CACHE_REDIS_HOST
  value: {{ .Release.Name }}-redis-master
- name: CACHE_REDIS_PORT
  value: "6379"
- name: CACHE_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
        name: {{ .Release.Name }}-redis
        key: redis-password
{{- end -}}
{{- end -}}

{{/*
Define CORS origin domains
For the node library used by Directus, this needs to be a string or an array
represented by a string like so "[\"domain1\",\"domain2\"]". Ugly.
*/}}
{{- define "directus.corsOrigins" -}}
  {{- $origins := list -}}
  {{- if .Values.localaccess.enabled -}}
    {{- $port := default 4200 .Values.localaccess.port | toString -}}
    {{- $origins = append $origins ( printf "http://localhost:%s" $port ) -}}
  {{- end -}}
  {{- range .Values.corsOrigins -}}
    {{- $host := printf "https://%s" . -}}
    {{- $origins = append $origins $host -}}
  {{- end -}}
  {{- $originstr := join "," $origins -}}
  {{- printf "array:%s" $originstr -}}
{{- end -}}
