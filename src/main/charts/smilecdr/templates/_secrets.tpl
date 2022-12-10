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

      {{- /*
        Make sure we don't define the same Object twice. If we are specifying the same ARN twice in the values
        file we need to handle it differently.
      */ -}}
      {{- $uniqueArn := true -}}
      {{- range $origlistvalue := $sscsiObjects -}}
        {{- if eq $origlistvalue.objectName $v.secretARN -}}
          {{- /* Not unique, so disable object creation further down */ -}}
          {{- $uniqueArn = false -}}
          {{- /* Merging keys is not possible unless we refactor how the key handling
                 is done. Instead, for now at least, we will fail if the same secret
                 ARN is used, to avoid unexpected failures */ -}}
          {{- fail "You cannot specify the same AWS Secret ARN for multiple databases" -}}
        {{- end -}}
      {{- end -}}
      {{- if $uniqueArn -}}
        {{- $sscsiObject := dict "objectName" (required "You must provide `secretARN` for the DB credentials secret" $v.secretARN) -}}
        {{- $jmesPathList := list (dict "path" (default "password" $v.passKey) "objectAlias" "db-password") -}}
        {{- if hasKey $v "urlKey" -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" $v.urlKey "objectAlias" "db-host") -}}
        {{- end -}}
        {{- if hasKey $v "userKey" -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" $v.userKey "objectAlias" "db-user") -}}
        {{- end -}}
        {{- if hasKey $v "portKey" -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" $v.portKey "objectAlias" "db-port") -}}
        {{- end -}}
        {{- if hasKey $v "dbnameKey" -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" $v.dbnameKey "objectAlias" "db-dbname") -}}
        {{- end -}}
        {{- $_ := set $sscsiObject "jmesPath" $jmesPathList -}}
        {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
      {{- end -}}
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
      {{- $sscsiSyncedSecret := dict "secretName" (required "You must provide `secretName` for the DB credentials secret" $v.secretName) -}}
      {{- $_ := set $sscsiSyncedSecret "type" "Opaque" -}}
      {{- $dataList := list (dict "key" (default "password" $v.passKey) "objectName" "db-password") -}}
      {{- if hasKey $v "urlKey" -}}
        {{- $dataList = append $dataList (dict "key" $v.urlKey "objectName" "db-host") -}}
      {{- end -}}
      {{- if hasKey $v "userKey" -}}
        {{- $dataList = append $dataList (dict "key" $v.userKey "objectName" "db-user") -}}
      {{- end -}}
      {{- if hasKey $v "portKey" -}}
        {{- $dataList = append $dataList (dict "key" $v.portKey "objectName" "db-port") -}}
      {{- end -}}
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
