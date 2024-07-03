{{- define "messagebroker.amq.config" -}}
  {{- $amqConfig := dict -}}
  {{- if and .Values.messageBroker.external.enabled (eq .Values.messageBroker.external.type "activemq") -}}
    {{- $amqConfig = .Values.messageBroker.external.config -}}
    {{- $_ := required "You must provide an address for your Active MQ server" ($amqConfig.connection).address -}}
    {{- $_ := set $amqConfig "enabled" "true" -}}

    {{- $secretSpec := deepCopy $amqConfig.authentication -}}

    {{- /* Set the name and suffixing for the secret object */ -}}
    {{- $_ := set $secretSpec "name" (default "amq" $secretSpec.name) -}}

    {{- /* Set the key mapping so that the correct secret object keys get created for imagePullSecrets*/ -}}
    {{- $_ := set $secretSpec "secretKeyMap" dict -}}

    {{- $keyMapping := dict "secretKeyName" "username" -}}
    {{- $_ := set $keyMapping "k8sSecretKeyName" "username" -}}
    {{- $_ := set $keyMapping "envVarName" "REMOTE_ACTIVEMQ_USERNAME" -}}
    {{- $_ := set $secretSpec.secretKeyMap "username" $keyMapping -}}

    {{- $keyMapping := dict "secretKeyName" "password" -}}
    {{- $_ := set $keyMapping "k8sSecretKeyName" "password" -}}
    {{- $_ := set $keyMapping "envVarName" "REMOTE_ACTIVEMQ_PASSWORD" -}}
    {{- $_ := set $secretSpec.secretKeyMap "password" $keyMapping -}}

    {{- $_ := set $secretSpec "useKeyNamesAsAlias" true -}}
    {{- $_ := set $secretSpec "objectAliasDisabled" true -}}

    {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $ "secretSpec" $secretSpec) | fromYaml -}}
    {{- $_ := set $amqConfig "secret" $secretConfig -}}
  {{- end -}}
  {{- $amqConfig | toYaml -}}
{{- end -}}


{{- /*
Define env vars that will be used for Active MQ configuration
*/ -}}
{{- define "messagebroker.amq.envVars" -}}
  {{- $envVars := list -}}
  {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
  {{- if $amqConfig.enabled -}}
    {{- /* Global Env vars */ -}}
    {{- $envVars = append $envVars (dict "name" "REMOTE_ACTIVEMQ_ADDRESS" "value" $amqConfig.connection.address) -}}
    {{- /* env vars from secrets */ -}}
    {{- if $amqConfig.secret -}}
      {{- range $env := $amqConfig.secret.envMap -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}
