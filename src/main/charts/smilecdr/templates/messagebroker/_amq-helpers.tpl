{{- define "messagebroker.amq.config" -}}
  {{- $amqConfig := dict -}}
  {{- if and .Values.messageBroker.external.enabled (eq .Values.messageBroker.external.type "activemq") -}}
    {{- $amqConfig = .Values.messageBroker.external.config -}}
    {{- $_ := required "You must provide an address for your Active MQ server" ($amqConfig.connection).address -}}
    {{- $_ := set $amqConfig "enabled" "true" -}}

    {{- $authSpec := $amqConfig.authentication -}}
    {{- if not (hasKey $authSpec "type") -}}
      {{- fail (printf "AMQ: You must provide authentication secret type.") -}}
    {{- end -}}
    {{- if contains $authSpec.type "sscsi k8sSecret" -}}
      {{- $defaultSecretNamePrefix := (printf "%s-amq" .Release.Name) -}}
      {{- $authType := (default "k8sSecret" $authSpec.type) -}}
      {{- /* Set default value. */ -}}
      {{- $secretName := printf "%s-credentials" $defaultSecretNamePrefix -}}
      {{- if eq $authType "sscsi" -}}
        {{- /* Set based on provided `secretName`. If not provided, leave default value untouched. */ -}}
        {{- if $authSpec.secretName -}}
          {{- $secretName = $authSpec.secretName -}}
        {{- end -}}
      {{- else if eq $authType "k8sSecret" -}}
        {{- /* Set based on provided `secretName`. If not provided, throw an error to the user. */ -}}
        {{- $secretName = required "AMQ: You must provide `secretName` for credentials if using `type: k8sSecret`" $authSpec.secretName -}}
      {{- end -}}
      {{- $_ := set $amqConfig "passwordSecretName" $secretName -}}
    {{- else -}}
      {{- fail (printf "AMQ: Credentials secret of type `%s` is not currently supported." $authSpec.type) -}}
    {{- end -}}
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
    {{- if contains $amqConfig.authentication.type "sscsi k8sSecret" -}}
      {{- $env := dict "name" "REMOTE_ACTIVEMQ_USERNAME" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $amqConfig.passwordSecretName "key" "username")) -}}
      {{- $envVars = append $envVars $env -}}
      {{- $env := dict "name" "REMOTE_ACTIVEMQ_PASSWORD" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $amqConfig.passwordSecretName "key" "password")) -}}
      {{- $envVars = append $envVars $env -}}
    {{- end -}}

  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}
