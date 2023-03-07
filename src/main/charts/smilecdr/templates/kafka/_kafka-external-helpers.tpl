{{- /*
This function just returns the config item, but also does some validation and sanitation
to avoid doing it in multiple places in the Helm Chart
*/ -}}
{{- define "kafka.external.config" -}}
  {{- $externalConfig := dict -}}
  {{- if .Values.messageBroker.external.enabled -}}
    {{- $externalConfig = .Values.messageBroker.external.config -}}
    {{- $kafkaConnectionType := (default "tls" ($externalConfig.connection).type) -}}
    {{- $kafkaAuthenticationType := (default "tls" ($externalConfig.authentication).type) -}}
    {{- $_ := set $externalConfig "enabled" "true" -}}
    {{- if not (contains $kafkaConnectionType "tls plaintext") -}}
      {{- fail (printf "Kafka: Connection type of `%s` is not supported." $kafkaConnectionType) -}}
    {{- end -}}
    {{- if not (contains $kafkaAuthenticationType "tls iam none") -}}
      {{- fail (printf "Kafka: Authentication type of `%s` is not supported." $kafkaAuthenticationType) -}}
    {{- end -}}
    {{- if and (eq $kafkaAuthenticationType "tls") (ne $kafkaConnectionType "tls") -}}
      {{- fail "Kafka: You can only use mTLS if Kafka connection type is `tls`" -}}
    {{- end -}}
    {{- if and (eq $kafkaAuthenticationType "iam") (ne $kafkaConnectionType "tls") -}}
      {{- fail "Kafka: You can only use IAM auth if Kafka connection type is `tls`" -}}
    {{- end -}}
  {{- end -}}
  {{- $externalConfig | toYaml -}}
{{- end -}}
