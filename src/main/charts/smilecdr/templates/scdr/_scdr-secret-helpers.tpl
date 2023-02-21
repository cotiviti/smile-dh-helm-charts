{{/*
Helper functions to help with secret handling

These charts support secrets being provided to containers using two methods
1. Using K8s Secret objects
2. Using the K8s Secrets Store CSI driver

K8s Secrets
If using K8s secrets, they can be created externally to this chart, or they can be created
by this chart using overridden values. The latter method is only intended as a quick-start
method and should only be used outside of initial testing.

K8s Secrets Store CSI driver
If using the CSI driver, you need to ensure the CSI driver and appropriate provider are
installed in the cluster. Then specify sscsi as the type

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

{{/*  */}}

{{/*
The following helpers are used to create configurations and volume mounts for
the Secrets Store CSI Driver.
Current providers supported:
* AWS Secrets Manager
*/}}

{{- define "sscsi.enabled" -}}
  {{- $sscsiEnabled := "false" -}}
  {{/* Enabled if using sscsi for image pull or db secrets */}}
  {{- if eq .Values.image.credentials.type "sscsi" -}}
    {{- $sscsiEnabled = "true" -}}
  {{- end -}}
  {{- if and (hasKey .Values "license") (eq (.Values.license).type "sscsi") -}}
    {{- $sscsiEnabled = "true" -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq ((.Values.database.external).credentials).type "sscsi") -}}
    {{- $sscsiEnabled = "true" -}}
  {{- end -}}
  {{- printf "%s" $sscsiEnabled -}}
{{- end -}}

{{- define "sscsi.secretProviderClassName" -}}
  {{- printf "%s-scdr" .Release.Name -}}
{{- end -}}

{{/*
Define `objects` for the Secrets Store CSI Secret Provider Custom Resource
These objects pull secrets from the configured vault and mount them into a
pod's filesystem
*/}}
{{- define "sscsi.objects" -}}
  {{- $sscsiObjects := list -}}
  {{- if eq .Values.image.credentials.type "sscsi" -}}
    {{- if eq .Values.image.credentials.provider "aws" -}}
      {{- $sscsiObject := dict "objectName" .Values.image.credentials.secretarn -}}
      {{- $jmesPath := dict "path" "dockerconfigjson" "objectAlias" "dockerconfigjson" -}}
      {{- $_ := set $sscsiObject "jmesPath" (list $jmesPath) -}}
      {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
      {{/*
        Define other providers here:
        {{- else if eq .Values.image.credentials.provider "otherprovider" -}}
        - add code to build $sscsiObject and append to $sscsiObjects
      */}}
    {{- end -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq ((.Values.database.external).credentials).type "sscsi") -}}
    {{- if eq ((.Values.database.external).credentials).provider "aws" -}}
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
          {{- $sscsiObject := dict "objectName" (required "You must provide `secretARN` as well as `secretName` for the DB credentials secret" $v.secretARN) -}}
          {{- $_ := set $sscsiObject "objectAlias" (required "You must provide `secretName` as well as `secretARN` for the DB credentials secret" $v.secretName) -}}
          {{- $jmesPathList := list (dict "path" (default "password" $v.passKey) "objectAlias" (printf "%s-db-password" $v.secretName)) -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" (default "host" $v.urlKey) "objectAlias" (printf "%s-db-host" $v.secretName)) -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" (default "username" $v.userKey) "objectAlias" (printf "%s-db-user" $v.secretName)) -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" (default "port" $v.portKey) "objectAlias" (printf "%s-db-port" $v.secretName)) -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" (default "dbname" $v.dbnameKey) "objectAlias" (printf "%s-db-dbname" $v.secretName)) -}}
          {{- $jmesPathList = append $jmesPathList (dict "path" (default "engine" $v.engineKey) "objectAlias" (printf "%s-db-engine" $v.secretName)) -}}
          {{- $_ := set $sscsiObject "jmesPath" $jmesPathList -}}
          {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
        {{- end -}}
      {{- end -}}
    {{/*
    Define other providers here:
    {{- else if eq ((.Values.database.external).credentials).provider "otherprovider" -}}
    - add code to build $sscsiObject and append to $sscsiObjects
    */}}
    {{- end -}}
  {{- end -}}
  {{- if eq (.Values.license).type "sscsi" -}}
    {{- if eq .Values.license.provider "aws" -}}
      {{- $sscsiObject := dict "objectName" .Values.license.secretarn -}}
      {{- $jmesPath := dict "path" "jwt" "objectAlias" "license.jwt" -}}
      {{- $_ := set $sscsiObject "jmesPath" (list $jmesPath) -}}
      {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
      {{/*
        Define other providers here:
        {{- else if eq .Values.image.credentials.provider "otherprovider" -}}
        - add code to build $sscsiObject and append to $sscsiObjects
      */}}
    {{- end -}}
  {{- end -}}
  {{/* Render the Secrets Store CSI objects*/}}
  {{- range $v := $sscsiObjects -}}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{- end -}}
{{- end -}}

{{/*
Define `secretObjects` for the Secrets Store CSI Secret Provider Custom Resource
These are used to create Kubernetes Secrets that are synced to mounted SSCSI secrets
*/}}
{{- define "sscsi.secretObjects" -}}
  {{- $sscsiSyncedSecrets := list -}}
  {{- if eq .Values.image.credentials.type "sscsi" -}}
    {{- $sscsiSyncedSecret := dict "secretName" (include "dockerconfigjson.secretName" .) -}}
    {{- $_ := set $sscsiSyncedSecret "type" "kubernetes.io/dockerconfigjson" -}}
    {{- $data := dict "key" ".dockerconfigjson" "objectName" "dockerconfigjson" -}}
    {{- $_ := set $sscsiSyncedSecret "data" (list $data) -}}
    {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq ((.Values.database.external).credentials).type "sscsi") -}}
    {{- range $v := .Values.database.external.databases -}}
      {{- $sscsiSyncedSecret := dict "secretName" (required "You must provide `secretName` for the DB credentials secret" $v.secretName) -}}
      {{- $_ := set $sscsiSyncedSecret "type" "Opaque" -}}
      {{- $dataList := list (dict "key" "password" "objectName" (printf "%s-db-password" $v.secretName)) -}}
      {{- $dataList = append $dataList (dict "key" "host" "objectName" (printf "%s-db-host" $v.secretName)) -}}
      {{- $dataList = append $dataList (dict "key" "username" "objectName" (printf "%s-db-user" $v.secretName)) -}}
      {{- $dataList = append $dataList (dict "key" "port" "objectName" (printf "%s-db-port" $v.secretName)) -}}
      {{- $dataList = append $dataList (dict "key" "dbname" "objectName" (printf "%s-db-dbname" $v.secretName)) -}}
      {{- $dataList = append $dataList (dict "key" "engine" "objectName" (printf "%s-db-engine" $v.secretName)) -}}
      {{- $_ := set $sscsiSyncedSecret "data" $dataList -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
    {{- end -}}
  {{- end -}}
  {{- if eq (.Values.license).type "sscsi" -}}
    {{- $sscsiSyncedSecret := dict "secretName" "cdrlicense" -}}
    {{- $_ := set $sscsiSyncedSecret "type" "Opaque" -}}
    {{- $data := dict "key" "jwt" "objectName" "license.jwt" -}}
    {{- $_ := set $sscsiSyncedSecret "data" (list $data) -}}
    {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
  {{- end -}}
  {{- range $v := $sscsiSyncedSecrets -}}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{- end -}}
{{- end -}}

{{/*
Define the volumes that will be used by Secrets Store CSI Driver to mount
secrets in to pods
*/}}
{{- define "sscsi.volumes" -}}
  {{- $sscsiVolumes := list -}}
  {{- if eq ((include "sscsi.enabled" . ) | trim ) "true" -}}
    {{- $volumeAttributes := dict "secretProviderClass" (include "sscsi.secretProviderClassName" .) -}}
    {{- $csi := dict "driver" "secrets-store.csi.k8s.io" "readOnly" true "volumeAttributes" $volumeAttributes -}}
    {{- $sscsiVolume := dict "name" (include "sscsi.secretProviderClassName" .) "csi" $csi -}}
    {{- $sscsiVolumes = append $sscsiVolumes $sscsiVolume -}}
  {{- end -}}
  {{- dict "list" $sscsiVolumes | toYaml -}}
{{- end -}}

{{/*
Define the volume mounts that will be used by Secrets Store CSI Driver to
mount secrets in to pods
*/}}
{{ define "sscsi.volumeMounts" }}
  {{- $sscsiVolumeMounts := list -}}
  {{- if eq ((include "sscsi.enabled" . ) | trim ) "true" -}}
    {{- $sscsiVolumeMount := dict "name" (include "sscsi.secretProviderClassName" .) -}}
    {{- $_ := set $sscsiVolumeMount "mountPath" "/mnt/sscsi" -}}
    {{- $_ := set $sscsiVolumeMount "readOnly" true -}}
    {{- $sscsiVolumeMounts = append $sscsiVolumeMounts $sscsiVolumeMount -}}
  {{- end -}}
  {{- dict "list" $sscsiVolumeMounts | toYaml -}}
{{ end }}
