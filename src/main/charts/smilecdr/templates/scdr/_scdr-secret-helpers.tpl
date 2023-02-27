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
Create list of image pull secrets to use.
Sets up default parameters so this can easily
be used elsewhere in the chart
*/}}
{{- define "imagePullSecrets" -}}
  {{- $imagePullSecrets := list -}}
  {{- range $i, $v := .Values.image.imagePullSecrets -}}
    {{- $name := printf "%s-scdr-image-pull-secrets" $.Release.Name -}}
    {{- $type := default "k8sSecret" .type -}}
    {{- if eq $type "k8sSecret" -}}
      {{- $name = .name -}}
      {{- $secretDict := dict "name" $name "type" "k8sSecret" -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else if eq $type "sscsi" -}}
      {{- $provider := required (printf "You must specify a provider when using sscsi for imagePullSecret %s" $name ) .provider -}}
      {{- $secretArn := required (printf "You must specify a secretArn when using sscsi for imagePullSecret %s" $name ) .secretArn -}}
      {{- $nameSuffix := "" -}}
      {{- if gt (len $.Values.image.imagePullSecrets) 1 -}}
        {{- $nameSuffix = printf "-%s" (trunc 8 (sha256sum $secretArn)) -}}
      {{- end -}}
      {{- $name = ternary .nameOverride (printf "%s%s" $name $nameSuffix) (hasKey . "nameOverride") -}}
      {{- $secretDict := dict "name" $name "type" "sscsi" "provider" $provider "secretArn" $secretArn -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else if eq $type "values" -}}
      {{- $registry := required (printf "You must specify a registry when using values for imagePullSecret %s" $name ) .registry -}}
      {{- $username := required (printf "You must specify a username when using values for imagePullSecret %s" $name ) .username -}}
      {{- $password := required (printf "You must specify a password when using values for imagePullSecret %s" $name ) .password -}}
      {{- $nameSuffix := "" -}}
      {{- if gt (len $.Values.image.imagePullSecrets) 1 -}}
        {{- $nameSuffix = printf "-%s" (trunc 8 (sha256sum $registry)) -}}
      {{- end -}}
      {{- $name = ternary .nameOverride (printf "%s%s" $name $nameSuffix) (hasKey . "nameOverride") -}}
      {{- $secretDict := dict "name" $name "type" "values" "registry" $registry "username" $username "password" $password -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else -}}
      {{- fail (printf "Secrets of type `%s` are not supported. Please use `sscsi` or `k8sSecret`" $type) -}}
    {{- end -}}
  {{- end -}}

  {{- /* Begin Deprecation Warning */ -}}
  {{- /* `image.credentials.type` is deprecated */ -}}
  {{- with (.Values.image.credentials) -}}
    {{- $name := printf "%s-scdr-image-pull-secrets" $.Release.Name -}}
    {{- $type := default "k8sSecret" .type -}}
    {{- if eq $type "k8sSecret" -}}
      {{- /* The legacy implementation only used the first secret in the list */ -}}
      {{- $name = (index .pullSecrets 0).name -}}
      {{- $secretDict := dict "name" $name "type" "k8sSecret" -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else if eq $type "sscsi" -}}
      {{- $provider := required (printf "You must specify a provider when using sscsi for imagePullSecret %s" $name ) .provider -}}
      {{- $secretArn := required (printf "You must specify a secretArn when using sscsi for imagePullSecret %s" $name ) .secretArn -}}
      {{- $secretDict := dict "name" $name "type" "sscsi" "provider" .provider "secretArn" .secretArn -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else if eq $type "values" -}}
      {{- $secretDict := dict "name" $name "type" "values" "registry" (default "docker.smilecdr.com" .registry) "username" (default "docker-user" .username) "password" (default "pass" .password) -}}
      {{- $imagePullSecrets = append $imagePullSecrets $secretDict -}}
    {{- else -}}
      {{- fail (printf "Secrets of type `%s` are not supported. Please use `sscsi` or `k8sSecret`" $type) -}}
    {{- end -}}
  {{- end -}}
  {{- /* End Deprecation Warning */ -}}

  {{- if ne (len $imagePullSecrets) 0 -}}
    {{- toYaml $imagePullSecrets -}}
  {{- end -}}
{{- end -}}

{{/*
Concise version of the image pull secrets list, for use in podSpec
Re-creates list, only using the 'name' keys for each entry.
*/}}
{{- define "imagePullSecretsList" -}}
  {{- $list := list -}}
  {{- range $v := (include "imagePullSecrets" . | fromYamlArray ) -}}
    {{- $list = append $list (dict "name" $v.name ) -}}
  {{- end -}}
  {{- if ne (len $list) 0 -}}
    {{- printf "%v" (toYaml $list) -}}
  {{- else -}}
    {{- printf "[]" -}}
  {{- end -}}
{{- end -}}

{{/*
The following helpers are used to create configurations and volume mounts for
the Secrets Store CSI Driver.
Current providers supported:
* AWS Secrets Manager
*/}}

{{- define "sscsi.enabled" -}}
  {{- $sscsiEnabled := "false" -}}
  {{/* Enabled if using sscsi for image pull or db secrets */}}
  {{- range (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if eq .type "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
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
  {{- range (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if eq .type "sscsi" -}}
      {{- if eq .provider "aws" -}}
        {{- $sscsiObject := dict "objectName" .secretArn -}}
        {{- $jmesPath := dict "path" "dockerconfigjson" "objectAlias" .name -}}
        {{- $_ := set $sscsiObject "jmesPath" (list $jmesPath) -}}
        {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
        {{/*
          Define other providers here:
          {{- else if eq .Values.image.credentials.provider "otherprovider" -}}
          - add code to build $sscsiObject and append to $sscsiObjects
        */}}
      {{- else -}}
        {{- fail (printf "The `%s` Secrets Store CSI provider is not currently supported." .provider) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if and .Values.database.external.enabled (eq ((.Values.database.external).credentials).type "sscsi") -}}
    {{- if eq ((.Values.database.external).credentials).provider "aws" -}}
      {{- range $v := .Values.database.external.databases -}}
        {{- /*
          Make sure we don't define the same Object twice. If we are specifying the same ARN or secretName twice in the values
          file we need to handle it differently.
        */ -}}
        {{- $unique := true -}}
        {{- range $origlistvalue := $sscsiObjects -}}
          {{- if eq $origlistvalue.objectName (required "You must provide `secretArn` as well as `secretName` for the DB credentials secret" $v.secretArn) -}}
            {{- /* Not unique, so disable object creation further down */ -}}
            {{- $unique = false -}}
            {{- /* Merging keys is not possible unless we refactor how the key handling
                  is done. Instead, for now at least, we will fail if the same secret
                  ARN is used, to avoid unexpected failures */ -}}
            {{- fail "You cannot specify the same AWS Secret ARN for multiple databases" -}}
          {{- end -}}
          {{- if eq $origlistvalue.objectAlias (required "You must provide `secretName` as well as `secretArn` for the DB credentials secret" $v.secretName) -}}
            {{- /* Not unique, so disable object creation further down */ -}}
            {{- $unique = false -}}
            {{- /* Merging keys is not possible unless we refactor how the key handling
                  is done. Instead, for now at least, we will fail if the same secret
                  ARN is used, to avoid unexpected failures */ -}}
            {{- fail "You cannot specify the same K8s secretName for multiple databases" -}}
          {{- end -}}
        {{- end -}}
        {{- if $unique -}}
          {{- $sscsiObject := dict "objectName" $v.secretArn -}}
          {{- $_ := set $sscsiObject "objectAlias" $v.secretName -}}
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
    {{- else -}}
      {{- fail (printf "The `%s` Secrets Store CSI provider is not currently supported." ((.Values.database.external).credentials).provider) -}}
    {{- end -}}
  {{- end -}}
  {{- if eq (.Values.license).type "sscsi" -}}
    {{- if eq .Values.license.provider "aws" -}}
      {{- $sscsiObject := dict "objectName" .Values.license.secretArn -}}
      {{- $jmesPath := dict "path" "jwt" "objectAlias" "license.jwt" -}}
      {{- $_ := set $sscsiObject "jmesPath" (list $jmesPath) -}}
      {{- $sscsiObjects = append $sscsiObjects $sscsiObject -}}
      {{/*
        Define other providers here:
        {{- else if eq .Values.image.credentials.provider "otherprovider" -}}
        - add code to build $sscsiObject and append to $sscsiObjects
      */}}
    {{- else -}}
      {{- fail (printf "The `%s` Secrets Store CSI provider is not currently supported." .Values.license.provider) -}}
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
  {{- range (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if eq .type "sscsi" -}}
      {{- $sscsiSyncedSecret := dict "secretName" .name -}}
      {{- $_ := set $sscsiSyncedSecret "type" "kubernetes.io/dockerconfigjson" -}}
      {{- $data := dict "key" ".dockerconfigjson" "objectName" .name -}}
      {{- $_ := set $sscsiSyncedSecret "data" (list $data) -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $sscsiSyncedSecret -}}
    {{- end -}}
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
