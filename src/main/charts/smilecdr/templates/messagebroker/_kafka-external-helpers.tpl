{{- /*
Lightweight template to determine if external Kafka is enabled
*/ -}}
{{- define "kafka.external.enabled" -}}
  {{- $externalKafkaEnabled := "false" -}}
  {{- if .Values.messageBroker.external.enabled -}}
    {{- $externalKafkaEnabled = "true" -}}
  {{- end -}}
  {{- $externalKafkaEnabled -}}
{{- end -}}

{{- /*
This function just returns the config item, but also does some validation and sanitation
to avoid doing it in multiple places in the Helm Chart
*/ -}}
{{- define "kafka.external.config" -}}
  {{- $externalConfig := dict -}}
  {{- if eq ((include "kafka.external.enabled" . ) | trim ) "true" -}}
    {{- $externalConfig = .Values.messageBroker.external.config -}}
    {{- $kafkaConnectionType := (default "tls" ($externalConfig.connection).type) -}}
    {{- $kafkaAuthenticationType := (default "tls" ($externalConfig.authentication).type) -}}
    {{- $_ := set $externalConfig "enabled" "true" -}}
    {{- if not (contains $kafkaConnectionType "ssl tls plaintext") -}}
      {{- fail (printf "Kafka: Connection type of `%s` is not supported." $kafkaConnectionType) -}}
    {{- end -}}
    {{- if not (contains (lower $kafkaAuthenticationType) "iam mtls tls password plain sasl/plain none") -}}
      {{- fail (printf "Kafka: Authentication type of `%s` is not supported." $kafkaAuthenticationType) -}}
    {{- end -}}
    {{- if and (contains $kafkaAuthenticationType "mtls tls") (not (contains $kafkaConnectionType "ssl tls")) -}}
      {{- fail "Kafka: You can only use mTLS auth if Kafka connection type is `tls`" -}}
    {{- end -}}
    {{- if and (eq $kafkaAuthenticationType "iam") (not (contains $kafkaConnectionType "ssl tls")) -}}
      {{- fail "Kafka: You can only use IAM auth if Kafka connection type is `tls`" -}}
    {{- end -}}
  {{- end -}}
  {{- $externalConfig | toYaml -}}
{{- end -}}
