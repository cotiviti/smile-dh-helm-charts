{{- /*
Lightweight template to determine if Strimzi is enabled
*/ -}}
{{- define "kafka.strimzi.enabled" -}}
  {{- $strimziEnabled := "false" -}}
  {{- if .Values.messageBroker.strimzi.enabled -}}
    {{- $strimziEnabled = "true" -}}
  {{- end -}}
  {{- $strimziEnabled -}}
{{- end -}}

{{- /*
This function just returns the config items, but also does some validation and sanitation
to avoid doing it in multiple places in the Helm Chart
*/ -}}
{{- define "kafka.strimzi.spec" -}}
  {{- $strimziSpec := dict -}}
  {{- if eq ((include "kafka.strimzi.enabled" . ) | trim ) "true" -}}
    {{- /* if .Values.messageBroker.strimzi.enabled */ -}}
    {{- if hasKey .Values.messageBroker.strimzi "config" -}}
      {{- /* Deprecated */ -}}
      {{- $strimziSpec = .Values.messageBroker.strimzi.config -}}
    {{- else -}}
      {{- $strimziSpec = .Values.messageBroker.strimzi -}}
    {{- end -}}
    {{- $strimziKafkaSpec := $strimziSpec.kafka -}}
    {{- $kafkaConnectionType := (default "tls" ($strimziKafkaSpec.connection).type) -}}
    {{- $kafkaAuthenticationType := (default "tls" ($strimziKafkaSpec.authentication).type) -}}

    {{- if (eq $kafkaAuthenticationType "tls") -}}
      {{- /* Add user as superUser if authentication is enabled */ -}}
      {{- /* TODO: Revisit the default permissions here */ -}}
      {{- /* $_ := set $strimziSpec "superUsers" (list (printf "CN=%s-kafka-user" .Release.Name)) */ -}}
      {{- $_ := set $strimziKafkaSpec "authorization" (dict "superUsers" (list (printf "CN=%s-kafka-user" .Release.Name))) -}}
    {{- end -}}
    {{- /* Set up some values based on replica count */ -}}
    {{- /* Set minInSyncReplicas to one less than replicas, with a minimum of 1 */ -}}
    {{- $kafkaReplicas := $strimziKafkaSpec.replicas | int -}}
    {{- $minInSyncReplicas := 1 -}}
    {{- if gt $kafkaReplicas 2 -}}
      {{- $minInSyncReplicas = sub $kafkaReplicas 1 -}}
    {{- end -}}
    {{- /* $_ := set $strimziKafkaSpec "minInSyncReplicas" $minInSyncReplicas */ -}}

    {{- /* Generate Kafka Kafka config items that get passed in to the Strimzi kafka.config section */ -}}
    {{- $_ := set $strimziKafkaSpec "config" dict -}}
    {{- $_ := set $strimziKafkaSpec.config "offsets.topic.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziKafkaSpec.config "transaction.state.log.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziKafkaSpec.config "transaction.state.log.min.isr" $minInSyncReplicas -}}
    {{- $_ := set $strimziKafkaSpec.config "default.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziKafkaSpec.config "min.insync.replicas" $minInSyncReplicas -}}
    {{- $_ := set $strimziKafkaSpec.config "inter.broker.protocol.version" $strimziKafkaSpec.protocolVersion -}}
    {{- $_ := set $strimziKafkaSpec.config "group.initial.rebalance.delay.ms" 3000 -}}
    {{- if hasKey $strimziKafkaSpec "deleteTopicEnable" -}}
      {{- $_ := set $strimziKafkaSpec.config "delete.topic.enable" $strimziKafkaSpec.deleteTopicEnable -}}
    {{- end -}}

    {{- if .Values.messageBroker.manageTopics -}}
      {{- $_ := set $strimziKafkaSpec.config "auto.create.topics.enable" false -}}
    {{- else -}}
      {{- $_ := set $strimziKafkaSpec.config "auto.create.topics.enable" true -}}
    {{- end -}}

    {{- /* TODO: Implement config override here.
        Just merge $strimziKafkaSpec from values. */ -}}

    {{- if not (contains $kafkaConnectionType "tls plaintext") -}}
      {{- fail (printf "Strimzi: Connection type of `%s` is not supported." $kafkaConnectionType) -}}
    {{- end -}}
    {{- if not (contains $kafkaAuthenticationType "tls none") -}}
      {{- fail (printf "Strimzi: Authentication type of `%s` is not supported." $kafkaAuthenticationType) -}}
    {{- end -}}
    {{- if and (eq $kafkaAuthenticationType "tls") (ne $kafkaConnectionType "tls") -}}
      {{- fail "Strimzi: You can only use mTLS if Kafka connection type is `tls`" -}}
    {{- end -}}
  {{- end -}}
  {{- $strimziSpec | toYaml -}}
{{- end -}}
