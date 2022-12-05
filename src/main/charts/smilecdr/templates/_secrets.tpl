{{/*
Helper functions to help with secret handling

These charts support secrets being provided to containers using two methods
1. Using K8s Secret objects
2. Using the K8s Secrets Store CSI driver

K8s Secrets
If using K8s secrets, they can be created externally to this chart, or they can be created
by this chart using overridden values. The latter method is only intended as a quick-start
method and should only be used in test or demo type environments.

K8s Secrets Store CSI driver
If using the CSI driver, you need to ensure the CSI driver and appropriate provider are
installed in the cluster. Then specify sscsi as the type

* Docker Config auth
  Can create a docker config auth file from credentials passed in via Helm values file
  Can use a docker config auth file (.docker/config.json)
  Can use externally provisioned K8s Secret

*/}}

{{/*
Create the name of the image pull secrets to use
*/}}
{{- define "dockerconfigjson.secretName" -}}
{{- if eq (required "You must provide image repository credentials to use this Helm Chart" .Values.image.credentials.type) "extsecret" }}
{{- with index .Values.image.credentials.pullSecrets 0 -}}
{{- .name }}
{{- end -}}
{{- else }}
{{- printf "%s-scdr-image-pull-secrets" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Generate plaintext docker/config.json text
*/}}
{{- define "dockerconfigjson.plaintext" }}
  {{- if eq .Values.image.credentials.type "values"}}
    {{- print "{\"auths\":{" }}
      {{- range $index, $item := .Values.image.credentials.values }}
        {{- if $index }}
        {{- print "," }}
        {{- end }}
        {{- printf "\"%s\":{\"auth\":\"%s\"}" (default "https://index.docker.io/v1/" $item.registry) (printf "%s:%s" $item.username $item.password | b64enc) }}
      {{- end }}
    {{- print "}}" }}
  {{- end }}
{{- end }}

{{/*
Generate base64 encoded docker/config.json from plain text
*/}}
{{- define "dockerconfigjson.encoded" }}
  {{- include "dockerconfigjson.plaintext" . | b64enc }}
{{- end }}


{{/*
Generate SecretProviderClass Objects
*/}}

{{- define "sscsi.enabled" -}}
  {{ $sscsiEnabled := "false" }}
  {{ if eq .Values.image.credentials.type "sscsi" }}
    {{ $sscsiEnabled = "true" }}
  {{ end }}
  {{ if and .Values.database.external.enabled (eq .Values.database.external.credentialsSource "sscsi-aws") }}
    {{ $sscsiEnabled = "true" }}
  {{ end }}
  {{- printf "%s" $sscsiEnabled -}}
{{- end -}}

{{- define "sscsi.secretProviderClassName" -}}
  {{- printf "%s-scdr" .Release.Name -}}
{{- end -}}

{{- define "sscsi.objects" -}}
  {{- $sscsiObjects := list -}}
  {{- if eq .Values.image.credentials.type "sscsi" -}}
    {{- if eq .Values.image.credentials.provider "aws" -}}
      {{- $sscsiObject := dict "objectName" .Values.image.credentials.secretarn -}}
      {{- $jmesPath := dict "path" "dockerconfigjson" "objectAlias" "dockerconfigjson" -}}
      {{- $_ := set $sscsiObject "jmesPath" (list $jmesPath) -}}
      {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
    {{- end -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq .Values.database.external.credentialsSource "sscsi-aws") -}}
    {{- range $v := .Values.database.external.databases -}}
      {{- $sscsiObject := dict "objectName" (required "You must provide an AWS secret ARN for the DB credentials secret" $v.secretARN) -}}
      {{- $jmesPathList := list (dict "path" "username" "objectAlias" "db-user") -}}
      {{- $jmesPathList = append $jmesPathList (dict "path" "password" "objectAlias" "db-password") -}}
      {{- $jmesPathList = append $jmesPathList (dict "path" "host" "objectAlias" "db-host") -}}
      {{- $_ := set $sscsiObject "jmesPath" $jmesPathList -}}
      {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
    {{- end -}}
  {{- end -}}
  {{- range $v := $sscsiObjects -}}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{- end -}}
{{- end -}}

{{- define "sscsi.secretObjects" -}}
  {{- $sscsiSyncedSecrets := list -}}
  {{- if eq .Values.image.credentials.type "sscsi" -}}
    {{- $sscsiSyncedSecret := dict "secretName" (include "dockerconfigjson.secretName" .) -}}
    {{- $_ := set $sscsiSyncedSecret "type" "kubernetes.io/dockerconfigjson" -}}
    {{- $data := dict "key" ".dockerconfigjson" "objectName" "dockerconfigjson" -}}
    {{- $_ := set $sscsiSyncedSecret "data" (list $data) -}}
    {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq .Values.database.external.credentialsSource "sscsi-aws") -}}
    {{- range $v := .Values.database.external.databases -}}
      {{- $sscsiSyncedSecret := dict "secretName" $v.secretName -}}
      {{- $_ := set $sscsiSyncedSecret "type" "Opaque" -}}
      {{- $dataList := list (dict "key" "host" "objectName" "db-host") -}}
      {{- $dataList = append $dataList (dict "key" "user" "objectName" "db-user") -}}
      {{- $dataList = append $dataList (dict "key" "password" "objectName" "db-password") -}}
      {{- $_ := set $sscsiSyncedSecret "data" $dataList -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
    {{- end -}}
  {{- end -}}
  {{- range $v := $sscsiSyncedSecrets -}}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{- end -}}
{{- end -}}

{{ define "sscsi.volume" }}
list:
{{ if eq ((include "sscsi.enabled" . ) | trim ) "true" }}
- name: {{ include "sscsi.secretProviderClassName" . }}
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ include "sscsi.secretProviderClassName" . }}
{{ else }}
  []
{{ end }}
{{ end }}

{{ define "sscsi.volumeMount" }}
list:
{{ if eq ((include "sscsi.enabled" . ) | trim ) "true" }}
- name: {{ include "sscsi.secretProviderClassName" . }}
  mountPath: "/mnt/sscsi"
  readOnly: true
{{ else }}
  []
{{ end }}
{{ end }}
