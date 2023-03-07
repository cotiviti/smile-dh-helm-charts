{{- /*
This function just returns the config items, but also does some validation and sanitation
to avoid doing it in multiple places in the Helm Chart
*/ -}}
{{- define "kafka.strimzi.config" -}}
  {{- $strimziConfig := dict -}}
  {{- if .Values.messageBroker.strimzi.enabled -}}
    {{- $strimziConfig = .Values.messageBroker.strimzi.config -}}
    {{- $kafkaConnectionType := (default "tls" ($strimziConfig.connection).type) -}}
    {{- $kafkaAuthenticationType := (default "tls" ($strimziConfig.authentication).type) -}}
    {{- $_ := set $strimziConfig "enabled" "true" -}}
    {{- if (eq $kafkaAuthenticationType "tls") -}}
      {{- /* Add user as superUser if authentication is enabled */ -}}
      {{- /* TODO: Revisit the default permissions here */ -}}
      {{- $_ := set $strimziConfig "superUsers" (list (printf "CN=%s-kafka-user" .Release.Name)) -}}
    {{- end -}}
    {{- /* Set up some values based on replica count */ -}}
    {{- /* Set minInSyncReplicas to one less than replicas, with a minimum of 1 */ -}}
    {{- $kafkaReplicas := $strimziConfig.kafka.replicas | int -}}
    {{- $minInSyncReplicas := 1 -}}
    {{- if gt $kafkaReplicas 2 -}}
      {{- $minInSyncReplicas = sub $kafkaReplicas 1 -}}
    {{- end -}}
    {{- $_ := set $strimziConfig.kafka "minInSyncReplicas" $minInSyncReplicas -}}

    {{- /* Generate actual config items that get passed in to the Strimzi kafka.config section */ -}}
    {{- $_ := set $strimziConfig "config" dict -}}
    {{- $_ := set $strimziConfig.config "offsets.topic.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziConfig.config "transaction.state.log.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziConfig.config "transaction.state.log.min.isr" $minInSyncReplicas -}}
    {{- $_ := set $strimziConfig.config "default.replication.factor" $kafkaReplicas -}}
    {{- $_ := set $strimziConfig.config "min.insync.replicas" $minInSyncReplicas -}}
    {{- $_ := set $strimziConfig.config "inter.broker.protocol.version" $strimziConfig.protocolVersion -}}
    {{- $_ := set $strimziConfig.config "group.initial.rebalance.delay.ms" 3000 -}}
    {{- $_ := set $strimziConfig.config "auto.create.topics.enable" $strimziConfig.autoCreateTopicsEnable -}}
    {{- $_ := set $strimziConfig.config "delete.topic.enable" $strimziConfig.autoCreateTopicsEnable -}}

    {{- /* TODO: Implement config override here */ -}}

    {{- if .Values.messageBroker.manageTopics -}}
      {{- $_ := set $strimziConfig "autoCreateTopicsEnable" false -}}
    {{- else -}}
      {{- $_ := set $strimziConfig "autoCreateTopicsEnable" true -}}
    {{- end -}}
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
  {{- $strimziConfig | toYaml -}}
{{- end -}}
