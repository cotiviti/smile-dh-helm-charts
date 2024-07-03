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
Secrets are used in a number of places.
In each case, the logic to determine the secret type has been repeated
in an inconsistent manner.

This helper is the single place to deal with this and can be used
anywhere in the chart that needs secrets injected.

Pass in root context as `rootCTX` and a `secretSpec` object as `secretSpec`.
secretSpec should contain the raw configuration from the values file as well
as any contextually required info.
Returns... stuff?

*/}}
{{- define "sdhCommon.secretConfig" -}}
  {{- /* Add function call tracing for troubleshooting rendering performance issues */ -}}
  {{- if (.Values).enableFunctionCounting -}}
    {{- $_ := set .Values.templateCalls "secretConfig" (add (default 0 .Values.templateCalls.secretConfig) 1) -}}
  {{- end -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $secretSpec := get . "secretSpec" -}}
  {{- /*
  secretSpec:
    # You must provide name or secretName at the minimum.
    # If you only provide name, secret name will be generated using release name
    name: Optional, used to auto generate name
    nameSuffix: Optional, used to auto generate name
    secretName: Optional, used to override name
    type: Optional, defaults to k8sSecret
    provider: Only required of type is sscsi
    secretArn: Only required of type is sscsi & provider is aws
    envName: Optional, provides environment configuration
    mountPath: Optional, provides secret mounting configuration
  */ -}}

  {{- /* Determine secret name */ -}}
  {{- $name := "" -}}
  {{- if $secretSpec.secretName -}}
    {{- $_ := set $secretSpec "secretName" (lower $secretSpec.secretName) -}}
    {{- $_ := set $secretSpec "name" (lower $secretSpec.secretName) -}}
  {{- else if $secretSpec.name -}}
    {{- $_ := set $secretSpec "name" (lower (printf "%s-%s" $rootCTX.Release.Name $secretSpec.name)) -}}
    {{- if $secretSpec.nameSuffix -}}
      {{-  $_ := set $secretSpec "name" (printf "%s-%s" $name $secretSpec.nameSuffix) -}}
    {{- end -}}

  {{- else -}}
    {{- fail (printf "You must provide `secretName` or `name` for secret configurations.") -}}
  {{- end -}}

  {{/* Determine secret type */}}
  {{- $_ := set $secretSpec "type" (default "k8sSecret" $secretSpec.type) -}}
  {{- if not (contains $secretSpec.type "k8sSecret sscsi") -}}
    {{- fail (printf "Secret type of `%s` is not supported. Please use `sscsi` or `k8sSecret`" $secretSpec.type) -}}
  {{- end -}}

  {{- /* Determine sscsi config */ -}}
  {{- if eq $secretSpec.type "sscsi" -}}
    {{- $_ := set $secretSpec "sscsiProvider" (required (printf "You must specify a provider when using sscsi for secret %s" $name ) $secretSpec.provider) -}}

    {{- /* Implementation for AWS Secrets Manager provider */ -}}
    {{- if eq (lower $secretSpec.provider) "aws" -}}
      {{- $_ := required (printf "You must specify a secretArn when using sscsi for secret %s" $name ) $secretSpec.secretArn -}}
      {{- $_ := required (printf "A dict of secret key mappings must be provided when using sscsi for secret %s" $name ) $secretSpec.secretKeyMap -}}
      {{- if $secretSpec.useArnShaSuffix -}}
        {{- $nameSuffix := trunc 8 (sha256sum $secretSpec.secretArn) -}}
        {{- $_ := set $secretSpec "name" (printf "%s-%s" $secretSpec.name $nameSuffix) -}}
      {{- end -}}

      {{- /* For each AWS secrets manager secret, we will need the following:
          * SecretProviderClass.spec.parameters.objects object with:
            objectName <Secrets Manager ARN>
            objectAlias <Alias for referencing this secret elsewhere in SecretProviderClass resource> Only required if syncing secret to k8s secret.
            jmesPath: <List of jmesPathSpec> Only required if syncing secret to k8s secret.

            jmesPathSpec:
              path: <key name in secrets manager secret>
              objectAlias <Alias for referencing this key elsewhere in SecretProviderClass resource>

          For secrets that are to be synced to K8s secrets, we need the following:
          * SecretProviderClass.spec.secretObjects object with:
            secretName: <K8s Secret resource name>
            type: <K8s secret type> Defaults to 'Opaque'
            data: <List of dataSpec>

            dataSpec:
              key: <Key to use in the K8s secret>
              objectName: <ObjectName or ObjectAlias from SecretProviderClass.spec.parameters.objects object

          */ -}}

      {{- /* Generate SecretProviderClass.spec.parameters.objects object */ -}}
      {{- $sscsiParameterObject := dict "objectName" $secretSpec.secretArn -}}
      {{- if not $secretSpec.objectAliasDisabled -}}
        {{- $_ := set $sscsiParameterObject "objectAlias" $secretSpec.name -}}
      {{- end -}}

      {{- /* Only create jmesPath, secretObject and environment map entries if we are syncing the secret */ -}}
      {{- $syncSecret := false -}}

      {{- $sscsiSecretObject := dict "secretName" $secretSpec.name -}}

      {{- $jmesPathList := list -}}
      {{- $dataSpecList := list -}}

      {{- range $keyName, $keySpec := $secretSpec.secretKeyMap -}}
        {{- if or $secretSpec.syncSecret (hasKey $keySpec "envVarName") (hasKey $keySpec "mountSpec") -}}
          {{- $syncSecret = true -}}
          {{- /* Define the alias used for this key */ -}}
          {{- $objectAlias := $secretSpec.name -}}

          {{- /* Suffix is only needed if there are multiple keys to map */ -}}
          {{- if gt (len $secretSpec.secretKeyMap) 1 -}}
            {{- /* Added for compatibility with old mechanism. Allows setting of objectAlias
                such as <secretname>-<extraSuffix>-<key>
                */ -}}
            {{- $internalName := ternary $keySpec.internalName $keyName (hasKey $keySpec "internalName") -}}
            {{- $aliasSuffix := ternary (printf "%s-%s" $secretSpec.objectAliasExtraSuffix $internalName) $internalName (hasKey $secretSpec "objectAliasExtraSuffix") -}}
            {{- $objectAlias = (printf "%s-%s" $secretSpec.name $aliasSuffix)  -}}
          {{- end -}}

          {{- $k8sSecretKeyName := ternary $keySpec.k8sSecretKeyName $keySpec.secretKeyName (hasKey $keySpec "k8sSecretKeyName") -}}
          {{- if $secretSpec.useKeyNamesAsAlias -}}
            {{- $objectAlias = $k8sSecretKeyName -}}
          {{- else if $secretSpec.useKeyMapAsAlias -}}
            {{- $objectAlias = $keyName -}}
          {{- end -}}

          {{- /* Define and add the SecretProviderClass.spec.parameters.objects.jmesPath for this key */ -}}
          {{- $jmesPath := dict "path" $keySpec.secretKeyName "objectAlias" $objectAlias -}}
          {{- $jmesPathList = append $jmesPathList $jmesPath -}}

          {{- /* Define and add the SecretProviderClass.spec.secretObjects.data for this key */ -}}

          {{- $dataSpec := dict "key" $k8sSecretKeyName "objectName" $objectAlias -}}
          {{- /* This method uses the overridden key name for the env variable */ -}}
          {{- /* $dataSpec := dict "key" $keySpec.secretKeyName "objectName" $objectAlias */ -}}
          {{- /* This method uses the default key name for the env variable */ -}}
          {{- /* $dataSpec := dict "key" $keySpec.defaultKeyName "objectName" $objectAlias */ -}}
          {{- $dataSpecList = append $dataSpecList $dataSpec -}}

        {{- end -}}
      {{- end -}}

      {{- if $syncSecret -}}
        {{- /* Add jmesPath and data lists to their respective objects */ -}}
        {{- $_ := set $sscsiParameterObject "jmesPath" $jmesPathList -}}
        {{- $_ := set $sscsiSecretObject "data" $dataSpecList -}}

        {{- /* Set type for secretObject and add it to the secretSpec */ -}}
        {{- $_ := set $sscsiSecretObject "type" (default "Opaque" $secretSpec.secretObjectType) -}}
        {{- $_ := set $secretSpec "sscsiSecretObject" $sscsiSecretObject -}}
      {{- end -}}

      {{- /* Add sscsiParameterObject to the secretSpec */ -}}
      {{- $_ := set $secretSpec "sscsiParameterObject" $sscsiParameterObject -}}

      {{/*
      Define other providers here:
      {{- else if eq (lower $secretSpec.provider) "otherprovider" -}}
      - add code to build $sscsiObject and include in secretSpec
      */}}

    {{- else -}}
      {{- fail (printf "The `%s` Secrets Store CSI provider is not currently supported (E100)." $secretSpec.provider) -}}
    {{- end -}}

  {{- end -}}

  {{- /* Build the envMaps if required */ -}}
  {{- $envMap := list -}}
  {{- range $keyName, $keySpec := $secretSpec.secretKeyMap -}}
    {{- if $keySpec.envVarName -}}
      {{- $env := dict "name" $keySpec.envVarName -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $secretSpec.name "key" $keySpec.k8sSecretKeyName)) -}}
      {{- $envMap = append $envMap $env -}}
    {{- end -}}
  {{- end -}}

  {{- if gt (len $envMap) 0 -}}
    {{- /* Pass through environment mapping if required */ -}}
    {{- $_ := set $secretSpec "envMap" $envMap -}}
  {{- end -}}

  {{- /* Build the volume and mount Maps if required */ -}}
  {{- $volumeMap := list -}}
  {{- $volumeMountMap := list -}}
  {{- range $keyName, $keySpec := $secretSpec.secretKeyMap -}}
    {{- if $keySpec.mountSpec -}}
      {{- $volumeName := coalesce $secretSpec.volumeName $secretSpec.name -}}
      {{- $secretProjection := (dict "secretName" $secretSpec.secretName) -}}
      {{- $volume := dict "name" $volumeName "secret" $secretProjection -}}
      {{- $volumeMap = append $volumeMap $volume -}}

      {{- $volumeMount := dict "name" $volumeName -}}
      {{- $_ := set $volumeMount "mountPath" $keySpec.mountSpec.mountPath -}}
      {{- $_ := set $volumeMount "subPath" $keySpec.k8sSecretKeyName -}}
      {{- $_ := set $volumeMount "readOnly" true -}}
      {{- $volumeMountMap = append $volumeMountMap $volumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- if gt (len $volumeMap) 0 -}}
    {{- /* Pass through volume mount mapping if required */ -}}
    {{- $_ := set $secretSpec "volumeMap" $volumeMap -}}
  {{- end -}}
  {{- if gt (len $volumeMountMap) 0 -}}
    {{- /* Pass through volume mount mapping if required */ -}}
    {{- $_ := set $secretSpec "volumeMountMap" $volumeMountMap -}}
  {{- end -}}

  {{- $secretSpec | toYaml -}}
{{- end -}}

{{/*
Create list of image pull secrets to use.
Sets up default parameters so this can easily
be used elsewhere in the chart
*/}}
{{- define "imagePullSecrets" -}}
  {{- $imagePullSecrets := list -}}
  {{- range $i, $v := .Values.image.imagePullSecrets -}}
    {{- $secretSpec := deepCopy $v -}}
    {{- /* Set the name and suffixing for the secret object */ -}}
    {{- $_ := set $secretSpec "name" (default "scdr-image-pull-secrets" $secretSpec.name) -}}
    {{- if gt (len $.Values.image.imagePullSecrets) 1 -}}
      {{- $_ := set $secretSpec "useArnShaSuffix" true -}}
    {{- end -}}
    {{- /* Set the key mapping so that the correct secret object keys get created for imagePullSecrets*/ -}}
    {{- $keyMapping := dict "secretKeyName" "dockerconfigjson" -}}
    {{- $_ := set $keyMapping "k8sSecretKeyName" ".dockerconfigjson" -}}
    {{- $_ := set $secretSpec "secretKeyMap" (dict ".dockerconfigjson" $keyMapping) -}}
    {{- $_ := set $secretSpec "secretObjectType" "kubernetes.io/dockerconfigjson" -}}
    {{- $_ := set $secretSpec "objectAliasDisabled" true -}}
    {{- $_ := set $secretSpec "syncSecret" true -}}
    {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $ "secretSpec" $secretSpec) | fromYaml -}}
    {{- $imagePullSecrets = append $imagePullSecrets $secretConfig -}}
  {{- end -}}

  {{- /* Begin Deprecation Warning */ -}}
  {{- /* `image.credentials.type` has been removed */ -}}
  {{- with (.Values.image.credentials) -}}
    {{- $secretSpec := deepCopy . -}}
    {{- /* Set the name for the secret object */ -}}
    {{- $_ := set $secretSpec "name" (default "scdr-image-pull-secrets" $secretSpec.name) -}}

    {{- /* The legacy implementation only used the first secret in the list, if set */ -}}
    {{- if and $secretSpec.pullSecrets (gt (len $secretSpec.pullSecrets) 0) -}}
      {{- $_ := set $secretSpec "secretName" (index .pullSecrets 0).name -}}
    {{- end -}}

    {{- /* Set the key mapping so that the correct secret object keys get created for imagePullSecrets*/ -}}
    {{- $keyMapping := dict "secretKeyName" "dockerconfigjson" -}}
    {{- $_ := set $keyMapping "k8sSecretKeyName" ".dockerconfigjson" -}}
    {{- $_ := set $secretSpec "secretKeyMap" (dict ".dockerconfigjson" $keyMapping) -}}
    {{- $_ := set $secretSpec "secretObjectType" "kubernetes.io/dockerconfigjson" -}}
    {{- $_ := set $secretSpec "objectAliasDisabled" true -}}
    {{- $_ := set $secretSpec "syncSecret" true -}}
    {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $ "secretSpec" $secretSpec) | fromYaml -}}
    {{- $imagePullSecrets = append $imagePullSecrets $secretConfig -}}

  {{- end -}}

  {{- /* TODO: When removing this functionality, replace with the below. */ -}}
  {{- /* `image.credentials.type` has been removed */ -}}
  {{- /* if hasKey .Values.image "credentials" -}}
    {{- $errorMessage := printf "\n\nERROR: `image.credentials`\n" -}}
    {{- $errorMessage = printf "%s\n     The use of `image.credentials` is no longer supported and has been removed." $errorMessage -}}
    {{- $errorMessage = printf "%s\n     Please use `image.imagePullSecrets` instead." $errorMessage -}}
    {{- $errorMessage = printf "%s\n     Refer to the docs for more info on how to configure image pull secrets." $errorMessage -}}
    {{- fail $errorMessage -}}
  {{- end */ -}}

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
  {{- $list | toYaml -}}
{{- end -}}


{{- define "smilecdr.extraSecrets" -}}
  {{- $extraSecretsConf := dict -}}
  {{- $extraSecrets := list -}}
  {{- $sscsiEnabled := false -}}
  {{- range $theSecretName, $theSecretSpec := .Values.secrets -}}
    {{- $secretSpec := deepCopy $theSecretSpec -}}
    {{- /* Set the name and suffixing for the secret object */ -}}
    {{- /* TODO:
        * Validations: 'name',
        */ -}}
    {{- $_ := set $secretSpec "objectAliasDisabled" true -}}
    {{- $_ := set $secretSpec "syncSecret" true -}}
    {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $ "secretSpec" $secretSpec) | fromYaml -}}
    {{- $extraSecrets = append $extraSecrets $secretConfig -}}
    {{- if eq $secretConfig.type "sscsi" -}}
      {{- $sscsiEnabled = true -}}
    {{- end -}}
  {{- end -}}

  {{- if gt (len $extraSecrets) 0 -}}
    {{- $_ := set $extraSecretsConf "enabled" true -}}
    {{- $_ := set $extraSecretsConf "sscsiEnabled" $sscsiEnabled -}}
    {{- $_ := set $extraSecretsConf "secrets" $extraSecrets -}}
  {{- end -}}
  {{- $extraSecretsConf | toYaml -}}
{{- end -}}

{{/*
"sscsi.enabled" - Checks various configuration conditions to see if
Secrets Store CSI driver (sscsi) is being used.
*/}}
{{- define "sscsi.enabled" -}}
  {{- /* Add function call tracing for troubleshooting rendering performance issues */ -}}
  {{- if .Values.enableFunctionCounting -}}
    {{- $_ := set .Values.templateCalls "sscsiEnabled" (add (default 0 .Values.templateCalls.sscsiEnabled) 1) -}}
  {{- end -}}
  {{- $sscsiEnabled := "false" -}}
  {{/* Enabled if using sscsi for image pull secrets */}}
  {{- range $v := (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if eq $v.type "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
  {{- end -}}
  {{/* Enabled if any database secrets are using sscsi */}}
  {{- $extDBSecrets := include "smilecdr.database.external.secrets" . | fromYamlArray -}}
  {{- range $theDBSecretSpec := $extDBSecrets -}}
    {{- if eq $theDBSecretSpec.type "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
  {{- end -}}
  {{/* Enabled if using sscsi for Smile CDR license */}}
  {{- if and (hasKey .Values "license") (eq (.Values.license).type "sscsi") -}}
    {{- $sscsiEnabled = "true" -}}
  {{- end -}}
  {{/* Enabled if using sscsi for Kafka connection(TLS) or auth (mTLS) certificates */}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if $kafkaConfig.enabled -}}
    {{- if eq $kafkaConfig.connection.secretType "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
    {{- if eq $kafkaConfig.authentication.secretType "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
  {{- end -}}
  {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
  {{- if $amqConfig.enabled -}}
    {{- if eq $amqConfig.authentication.type "sscsi" -}}
      {{- $sscsiEnabled = "true" -}}
    {{- end -}}
  {{- end -}}
  {{- $extraSecrets := (include "smilecdr.extraSecrets" . | fromYaml) -}}
  {{- if $extraSecrets.sscsiEnabled -}}
    {{- $sscsiEnabled = "true" -}}
  {{- end -}}
  {{- $sscsiEnabled -}}
{{- end -}}

{{- define "sscsi.secretProviderClassName" -}}
  {{- /* Old resource naming does not include CDR node name as only a single Secret Provider Class is created */ -}}
  {{- if (.Values.oldResourceNaming) -}}
    {{- printf "%s-scdr" .Release.Name -}}
  {{- else -}}
    {{- printf "%s-scdrnode-%s" .Release.Name (lower .Values.cdrNodeId) -}}
  {{- end -}}
{{- end -}}

{{/*
Define `objects` for the Secrets Store CSI Secret Provider Custom Resource
These objects pull secrets from the configured vault and mount them into a
pod's filesystem
*/}}
{{- define "sscsi.objects" -}}
  {{- $sscsiObjects := list -}}
  {{- /* Include SSCSI Objects for Image Pull Secrets */ -}}
  {{- range $v := (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if $v.sscsiParameterObject -}}
      {{- $sscsiObjects = append $sscsiObjects $v.sscsiParameterObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* Get the canonical list of external DB secrets */ -}}
  {{- $extDBSecrets := include "smilecdr.database.external.secrets" . | fromYamlArray -}}
  {{- range $theDBSecretSpec := $extDBSecrets -}}
    {{- if $theDBSecretSpec.sscsiParameterObject -}}
      {{- $sscsiObjects = append $sscsiObjects $theDBSecretSpec.sscsiParameterObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for External Kafka certificates & credentials */ -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}

  {{- range $theKafkaSecretSpec := $kafkaConfig.secrets -}}
    {{- if $theKafkaSecretSpec.sscsiParameterObject -}}
      {{- $sscsiObjects = append $sscsiObjects $theKafkaSecretSpec.sscsiParameterObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for External ActiveMQ credentials */ -}}
  {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
  {{- if and $amqConfig.secret $amqConfig.secret.sscsiParameterObject -}}
    {{- $sscsiObjects = append $sscsiObjects $amqConfig.secret.sscsiParameterObject -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for CDR license */ -}}
  {{- $licenseConfig := (include "smilecdr.license" . | fromYaml) -}}
  {{- if and $licenseConfig.secret $licenseConfig.secret.sscsiParameterObject -}}
    {{- $sscsiObjects = append $sscsiObjects $licenseConfig.secret.sscsiParameterObject -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for extra secrets */ -}}
  {{- $extraSecrets := (include "smilecdr.extraSecrets" . | fromYaml) -}}
  {{- range $extraSecret :=  $extraSecrets.secrets -}}
    {{- if $extraSecret.sscsiParameterObject -}}
      {{- $sscsiObjects = append $sscsiObjects $extraSecret.sscsiParameterObject -}}
    {{- end -}}
  {{- end -}}

  {{- $sscsiObjects | toYaml -}}
{{- end -}}

{{/*
Define `secretObjects` for the Secrets Store CSI Secret Provider Custom Resource
These are used to create Kubernetes Secrets that are synced to mounted SSCSI secrets
*/}}
{{- define "sscsi.secretObjects" -}}
  {{- $sscsiSyncedSecrets := list -}}
  {{- range $theImagePullSecretSpec := (include "imagePullSecrets" . | fromYamlArray) -}}
    {{- if $theImagePullSecretSpec.sscsiSecretObject -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $theImagePullSecretSpec.sscsiSecretObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* External Database credentials */ -}}
  {{- $extDBSecrets := include "smilecdr.database.external.secrets" . | fromYamlArray -}}
  {{- range $theDBSecretSpec := $extDBSecrets -}}
    {{- if $theDBSecretSpec.sscsiSecretObject -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $theDBSecretSpec.sscsiSecretObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* External Kafka credentials */ -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
   {{- range $theKafkaSecretSpec := $kafkaConfig.secrets -}}
    {{- if $theKafkaSecretSpec.sscsiSecretObject -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $theKafkaSecretSpec.sscsiSecretObject -}}
    {{- end -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for External ActiveMQ credentials */ -}}
  {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
  {{- if and $amqConfig.secret $amqConfig.secret.sscsiSecretObject -}}
    {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $amqConfig.secret.sscsiSecretObject -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for CDR license */ -}}
  {{- $licenseConfig := (include "smilecdr.license" . | fromYaml) -}}
  {{- if and $licenseConfig.secret $licenseConfig.secret.sscsiSecretObject -}}
    {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $licenseConfig.secret.sscsiSecretObject -}}
  {{- end -}}

  {{- /* Include SSCSI Objects for extra secrets */ -}}
  {{- $extraSecrets := (include "smilecdr.extraSecrets" . | fromYaml) -}}
  {{- range $extraSecret :=  $extraSecrets.secrets -}}
    {{- if $extraSecret.sscsiSecretObject -}}
      {{- $sscsiSyncedSecrets = append $sscsiSyncedSecrets $extraSecret.sscsiSecretObject -}}
    {{- end -}}
  {{- end -}}

  {{- $sscsiSyncedSecrets | toYaml -}}
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
  {{- $sscsiVolumes | toYaml -}}
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
  {{- $sscsiVolumeMounts | toYaml -}}
{{ end }}
