{{- /*
Lightweight template to determine if Kafka is enabled
*/ -}}
{{- define "kafka.enabled" -}}
  {{- $kafkaEnabled := "false" -}}
  {{- /* Determine if this is being called in a 'cdrNode' context or root Helm Values context */ -}}
  {{- $ctx := dict -}}

  {{- if hasKey $.Values "nodeId"  -}}
    {{- /* This is a dynamically generated cdrNode, so we will just return if Kafka is enabled for *this* node */ -}}

    {{- $strimziEnabled := ternary true false (eq ((include "kafka.strimzi.enabled" . ) | trim ) "true") -}}
    {{- $externalEnabled := ternary true false (eq ((include "kafka.external.enabled" . ) | trim ) "true") -}}
    {{- if and $strimziEnabled $externalEnabled -}}
      {{- fail "You cannot enable strimzi and external Kafka together " -}}
    {{- end -}}
    {{- if or $strimziEnabled $externalEnabled -}}
      {{- $kafkaEnabled = "true" -}}
    {{- end -}}

  {{- else -}}
    {{- /* This is the root context, which means we need to cycle through all nodes to determine if Kafka is enabled in any of them */ -}}
    {{- /* We can simply do this with recursion */ -}}
    {{- range $theNodeName, $theNodeCtx := include "smilecdr.nodes" . | fromYaml -}}
      {{- if eq ((include "kafka.enabled" $theNodeCtx ) | trim ) "true" -}}
        {{- $kafkaEnabled = "true" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $kafkaEnabled -}}
{{- end -}}

{{- /*
This function builds some commonly used configuration for Kafka settings based
on either external or Strimzi settings.
*/ -}}
{{- define "kafka.config" -}}
  {{- $ctx := get . "Values" -}}

  {{- /* Some configurations only make sense in the context of a cdrNode */ -}}
  {{- /* This flag helps decide whether or not to render them */ -}}
  {{- $contextType := "root" -}}
  {{- if hasKey $ctx "nodeId"  -}}
    {{- $contextType = "cdrNode" -}}
  {{- end -}}
  {{- $strimziConfig := (include "kafka.strimzi.config" . | fromYaml) -}}
  {{- $externalConfig := (include "kafka.external.config" . | fromYaml) -}}
  {{- $kafkaConfig := dict "externalConfig" $externalConfig "strimziConfig" $strimziConfig -}}
  {{- /* if and $strimziConfig.enabled $externalConfig.enabled -}}
    {{- fail "You cannot enable strimzi and external Kafka together " -}}
  {{- end */ -}}
  {{- if or $strimziConfig.enabled $externalConfig.enabled -}}
    {{- /* Global Kafka config */ -}}
    {{- $_ := set $kafkaConfig "enabled" "true" -}}

    {{- /* Set default to tls + tls (mTLS) */ -}}
    {{- $kafkaConnectionType := "tls" -}}
    {{- /* $kafkaAuthenticationType := "tls" */ -}}
    {{- $kafkaAuthentication := dict "type" "tls" -}}
    {{- $kafkaConnectionSecretType := "" -}}
    {{- $kafkaAuthenticationSecretType := "" -}}
    {{- $kafkaBootstrapAddress := "" -}}
    {{- $autoCreateTopics := true -}}
    {{- if $strimziConfig.enabled -}}
      {{- /* Disable publicca by default */ -}}
      {{- $_ := set $kafkaConfig "publicca" false -}}
      {{- $kafkaConnectionType = ($strimziConfig.connection).type -}}
      {{- /* $kafkaAuthenticationType = ($strimziConfig.authentication).type */ -}}
      {{- $kafkaAuthentication = deepCopy (mergeOverwrite $kafkaAuthentication $strimziConfig.authentication) -}}
      {{- /* Settings for TLS with Strimzi */ -}}
      {{- if eq $kafkaConnectionType "tls" -}}
        {{- /* K8s secret name for Strimzi ca cert */ -}}
        {{- $_ := set $kafkaConfig "caCertSecretName" (printf "%s-cluster-ca-cert" .Release.Name) -}}
        {{- /* Kafka bootstrap servers for Strimzi tls listener */ -}}
        {{- /*TODO: Make the bootstrap address autoconfigure from the Strimzi configuration */ -}}
        {{- $kafkaBootstrapAddress = printf "%s-kafka-bootstrap:9093" .Release.Name -}}
      {{- else -}}
        {{- $kafkaBootstrapAddress = printf "%s-kafka-bootstrap:9093" .Release.Name -}}
      {{- end -}}
      {{- /* Set the K8s secret name for Strimzi user cert */ -}}
      {{- if eq $kafkaAuthentication.type "tls" -}}
        {{- $_ := set $kafkaConfig "userCertSecretName" (printf "%s-kafka-user" .Release.Name) -}}
      {{- end -}}
    {{- else if $externalConfig.enabled -}}
      {{- $kafkaBootstrapAddress = required "Kafka: You must provide `bootstrapAddress`" $externalConfig.connection.bootstrapAddress -}}
      {{- $kafkaConnectionType = ($externalConfig.connection).type -}}
      {{- /* $kafkaAuthenticationType = ($externalConfig.authentication).type */ -}}
      {{- $kafkaAuthentication = deepCopy (mergeOverwrite $kafkaAuthentication $externalConfig.authentication) -}}
      {{- $defaultSecretNamePrefix := (printf "%s-kafka" .Release.Name) -}}
      {{- if eq $kafkaConnectionType "tls" -}}
        {{- $caCertType := (default "public" (($externalConfig.connection).caCert).type) -}}
        {{- /* Set the K8s secret name for external Kafka ca cert based on provided `secretName` if any.
            If using `public` this is the only scenario where we enable use of public ca cert for Kafka.
            (i.e. if we are using an external Kafka and do not specify a cert, or explicitly set it to `public`)
            If using `sscsi` and `secretName` is not provided, it uses autogenerated default `<releaseName>-kafka-ca-cert`
            If using `k8sSecret` and `secretName` is not provided, throw an error to the user.
            Default to the `public` behaviour if no caCert is provided */ -}}
        {{- /* Set default value. */ -}}
        {{- $secretName := printf "%s-ca-cert" $defaultSecretNamePrefix -}}
        {{- if eq $caCertType "public" -}}
          {{- $_ := set $kafkaConfig "publicca" true -}}
        {{- else if eq $caCertType "sscsi" -}}
          {{- /* Set based on provided `secretName`. If not provided, leave default value untouched. */ -}}
          {{- if (($externalConfig.connection).caCert).secretName -}}
            {{- $secretName = (($externalConfig.connection).caCert).secretName -}}
          {{- end -}}
          {{- $kafkaAuthenticationSecretType := "" -}}
        {{- else if eq $caCertType "k8sSecret" -}}
          {{- /* Set based on provided `secretName`. If not provided, throw an error to the user. */ -}}
          {{- $secretName = required "Kafka: You must provide `secretName` for CA cert if using `type: k8sSecret`" (($externalConfig.connection).caCert).secretName -}}
        {{- else -}}
          {{- /* Fail as `caCert.type` is set to an unsupported value */ -}}
          {{- fail (printf "Kafka: CA certificate secret of type `%s` is not currently supported.") -}}
        {{- end -}}
        {{- $kafkaConnectionSecretType = $caCertType -}}
        {{- $_ := set $kafkaConfig "caCertSecretName" $secretName -}}
      {{- end -}}
      {{- /* if eq $kafkaAuthenticationType "tls" */ -}}
      {{- if eq $kafkaAuthentication.type "tls" -}}
        {{- $userCertType := (default "k8sSecret" (($externalConfig.authentication).userCert).type) -}}
        {{- /* Set the K8s secret name for external Kafka user cert based on provided `secretName` if any.
              If using `sscsi` and `secretName` is not provided, it uses autogenerated default `<releaseName>-kafka-user-cert``
              If using `k8sSecret` and `secretName` is not provided, throw an error to the user.
              Default to the `k8sSecret` behaviour if no userCert is provided */ -}}
        {{- /* Set default value. */ -}}
        {{- $secretName := printf "%s-user-cert" $defaultSecretNamePrefix -}}
        {{- if eq $userCertType "sscsi" -}}
          {{- /* Set based on provided `secretName`. If not provided, leave default value untouched. */ -}}
          {{- if (($externalConfig.authentication).userCert).secretName -}}
            {{- $secretName = (($externalConfig.authentication).userCert).secretName -}}
          {{- end -}}
        {{- else if eq $userCertType "k8sSecret" -}}
          {{- /* Set based on provided `secretName`. If not provided, throw an error to the user. */ -}}
          {{- $secretName = required "Kafka: You must provide `secretName` for user cert if using `type: k8sSecret`" (($externalConfig.authentication).userCert).secretName -}}
        {{- else -}}
          {{- /* Fail as `caCert.type` is set to an unsupported value */ -}}
          {{- fail (printf "Kafka: CA certificate secret of type `%s` is not currently supported.") -}}
        {{- end -}}
        {{- $kafkaAuthenticationSecretType = $userCertType -}}
        {{- $_ := set $kafkaConfig "userCertSecretName" $secretName -}}
      {{- end -}}
    {{- end -}}

    {{- /* Topic management */ -}}
    {{- /* Only supported in Strimzi right now */ -}}
    {{- if and .Values.messageBroker.manageTopics $strimziConfig.enabled -}}
      {{- /* Update the topics to be suitable for the existing Strimzi configuration */ -}}
      {{- range $k, $v := .Values.messageBroker.topics -}}
        {{- $_ := set (get $.Values.messageBroker.topics $k) "replicas" $strimziConfig.kafka.replicas -}}
      {{- end -}}
      {{- $_ := set $kafkaConfig "topics" .Values.messageBroker.topics -}}
      {{- $autoCreateTopics = false -}}
    {{- else -}}
      {{- $_ := set $kafkaConfig "topics" dict -}}
    {{- end -}}

    {{- $_ := set $kafkaConfig "connection" (dict "type" $kafkaConnectionType "secretType" $kafkaConnectionSecretType) -}}
    {{- $_ := set $kafkaConfig "authentication" $kafkaAuthentication -}}
    {{- $_ := set $kafkaConfig.authentication "secretType" $kafkaAuthenticationSecretType -}}
    {{- $_ := set $kafkaConfig "bootstrapAddress" $kafkaBootstrapAddress -}}
    {{- $_ := set $kafkaConfig "autoCreateTopics" $autoCreateTopics -}}


    {{- $_ := set $kafkaConfig "propertiesResourceName" $autoCreateTopics -}}

    {{- if hasKey $ctx.messageBroker "clientConfiguration" -}}
      {{- $_ := set $kafkaConfig "consumerProperties" (default (dict) (deepCopy $ctx.messageBroker.clientConfiguration.consumerProperties)) -}}
      {{- $_ := set $kafkaConfig "producerProperties" (get $ctx.messageBroker.clientConfiguration "producerProperties" ) -}}

    {{- end -}}

    {{- $consumerPropertiesData := include "kafka.consumer.properties.text" $kafkaConfig -}}
    {{- $producerPropertiesData := include "kafka.producer.properties.text" $kafkaConfig -}}

    {{- $_ := set $kafkaConfig "consumerPropertiesData" $consumerPropertiesData -}}
    {{- $_ := set $kafkaConfig "producerPropertiesData" $producerPropertiesData -}}
    {{- /* fail (printf "Context: %s" (toPrettyJson $ctx.nodeName)) */ -}}
    {{- $propsHashSuffix := ternary (printf "-%s" (include "smilecdr.getHashSuffix" (printf "%s/n%s" $consumerPropertiesData $producerPropertiesData))) "" $ctx.autoDeploy -}}
    {{- /* TODO: We can update the following if we wish to change the kafka properties CM resource naming schema later. */ -}}
    {{- /* fail (printf "%s-kafka-client-properties-%s-node%s" $.Release.Name ($ctx.nodeName | lower) $propsHashSuffix) */ -}}
    {{- /* if not $ctx.nodeName -}}
      {{- fail (printf "Context: %s" (toPrettyJson $ctx)) -}}
    {{- end */ -}}

    {{- /* Set name for Kafka client properties ConfigMap */ -}}
    {{- /* Only include node name in client properties if in 'cdrNode' context */ -}}
    {{- if eq $contextType "cdrNode" -}}
      {{- $_ := set $kafkaConfig "propertiesResourceName" (printf "%s-kafka-client-properties-%s-node%s" $.Release.Name ($ctx.nodeName | lower) $propsHashSuffix) -}}
      {{- /* TODO: Remove when `oldResourceNaming` is removed */ -}}
      {{- if $ctx.oldResourceNaming -}}
        {{- $_ := set $kafkaConfig "propertiesResourceName" (printf "%s-kafka-client-properties-%s-node%s" $.Release.Name ($ctx.nodeName | lower) $propsHashSuffix) -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := set $kafkaConfig "propertiesResourceName" (printf "%s-kafka-client-properties-%s" $.Release.Name $propsHashSuffix) -}}
    {{- end -}}

  {{- end -}}
  {{- $kafkaConfig | toYaml -}}
{{- end -}}

{{- /*
Define the volumes that will be used to mount Kafka certificates
in to pods
*/ -}}
{{- define "kafka.certificate.volumes" -}}
  {{- $ctx := get . "Values" -}}
  {{- $volumes := list -}}
  {{- /* $kafkaConfig := (include "kafka.config" . | fromYaml) */ -}}
  {{- /* This can be called in cdrNode or root contexts (For the Admin pod) */ -}}
  {{- /* When called in root context, we need to call the kafka config template first */ -}}
  {{- $kafkaConfig := dict -}}
  {{- if hasKey $ctx "nodeId"  -}}
    {{- $kafkaConfig = $ctx.kafka -}}
  {{- else -}}
    {{- $kafkaConfig = (include "kafka.config" . | fromYaml) -}}
  {{- end -}}
  {{- /* Mount CA cert if using TLS and private cert */ -}}
  {{- if and (eq $kafkaConfig.connection.type "tls") (not $kafkaConfig.publicca ) -}}
    {{- $secretProjection := (dict "secretName" $kafkaConfig.caCertSecretName) -}}
    {{- $certVolume := dict "name" "kafka-broker-ca-cert" "secret" $secretProjection -}}
    {{- $volumes = append $volumes $certVolume -}}
  {{- end -}}
  {{- /* Mount client cert if using mTLS */ -}}
  {{- if eq $kafkaConfig.authentication.type "tls" -}}
    {{- $secretProjection := (dict "secretName" $kafkaConfig.userCertSecretName) -}}
    {{- $certVolume := dict "name" "kafka-client-cert" "secret" $secretProjection -}}
    {{- $volumes = append $volumes $certVolume -}}
  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- /*
Define Kafka related volumes requird by Smile CDR pod
*/ -}}
{{- define "kafka.volumes" -}}
  {{- $volumes := list -}}

  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if $kafkaConfig.enabled -}}
  {{- /* if eq ((include "kafka.enabled" . ) | trim ) "true" */ -}}
    {{- /* $kafkaConfig := (include "kafka.config" . | fromYaml) */ -}}
    {{- /* if $kafkaConfig.enabled */ -}}

    {{- /* Mount client properties files */ -}}
    {{- $configMap := (dict "name" $kafkaConfig.propertiesResourceName) -}}
    {{- $propsVolume := dict "name" "kafka-client-config" "configMap" $configMap -}}
    {{- $volumes = append $volumes $propsVolume -}}
    {{- $volumes = concat $volumes (include "kafka.certificate.volumes" . | fromYamlArray) -}}

  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- /*
Define the volume mounts that will be used to mount Kafka certificates
in to pods
*/ -}}
{{- define "kafka.certificate.volumeMounts" -}}
  {{- $volumeMounts := list -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- /* Mount CA cert if using TLS and private cert */ -}}
  {{- if and (eq $kafkaConfig.connection.type "tls") (not $kafkaConfig.publicca ) -}}
    {{- $volumeMount := dict "name" "kafka-broker-ca-cert" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/classes/client_certificates/kafka-ca-cert.p12" -}}
    {{- $_ := set $volumeMount "subPath" "ca.p12" -}}
    {{- $_ := set $volumeMount "readOnly" true -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}
  {{- /* Mount client cert if using mTLS */ -}}
  {{- if eq $kafkaConfig.authentication.type "tls" -}}
    {{- $volumeMount := dict "name" "kafka-client-cert" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/classes/client_certificates/kafka-client-cert.p12" -}}
    {{- $_ := set $volumeMount "subPath" "user.p12" -}}
    {{- $_ := set $volumeMount "readOnly" true -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}

{{- /*
Define Kafka related volume mounts requird by Smile CDR container
*/ -}}
{{- define "kafka.volumeMounts" -}}
  {{- $volumeMounts := list -}}
  {{- if eq ((include "kafka.enabled" . ) | trim ) "true" -}}
    {{- /* Mount consumer properties file */ -}}
    {{- $volumeMount := dict "name" "kafka-client-config" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/classes/cdr_kafka_config/cdr-kafka-consumer-config.properties" -}}
    {{- $_ := set $volumeMount "subPath" "consumer.properties" -}}
    {{- $_ := set $volumeMount "readOnly" true -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
    {{- /* Mount producer properties file */ -}}
    {{- $volumeMount = dict "name" "kafka-client-config" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/classes/cdr_kafka_config/cdr-kafka-producer-config.properties" -}}
    {{- $_ := set $volumeMount "subPath" "producer.properties" -}}
    {{- $_ := set $volumeMount "readOnly" true -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
    {{- $volumeMounts = concat $volumeMounts (include "kafka.certificate.volumeMounts" . | fromYamlArray) -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}

{{- /*
Define env vars that will be used for Kafka certificate
passwords
*/ -}}
{{- define "kafka.envVars" -}}
  {{- $envVars := list -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if $kafkaConfig.enabled -}}
    {{- /* Global Env vars */ -}}
    {{- $envVars = append $envVars (dict "name" "KAFKA_BOOTSTRAP_ADDRESS" "value" $kafkaConfig.bootstrapAddress) -}}
    {{- /* Env vars if using TLS and private cert */ -}}
    {{- if eq $kafkaConfig.connection.type "tls" -}}
      {{- $envVars = append $envVars (dict "name" "KAFKA_SSL_ENABLED" "value" "true") -}}
      {{- if not $kafkaConfig.publicca -}}
        {{- $env := dict "name" "KAFKA_BROKER_CA_CERT_PWD" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $kafkaConfig.caCertSecretName "key" "ca.password")) -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}
    {{- else -}}
      {{- $envVars = append $envVars (dict "name" "KAFKA_SSL_ENABLED" "value" "false") -}}
    {{- end -}}
    {{- /* Env vars if using mTLS */ -}}
    {{- if eq $kafkaConfig.authentication.type "tls" -}}
      {{- $env := dict "name" "KAFKA_CLIENT_CERT_PWD" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $kafkaConfig.userCertSecretName "key" "user.password")) -}}
      {{- $envVars = append $envVars $env -}}
    {{- end -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}

{{/*
Define any file copies required by Kafka
*/}}
{{ define "kafka.customerlib.sources" }}

  {{- $customerlibFileSources := list -}}

  {{- /* Add Kafka MSK IAM Jar, only if auth type is set to `iam` */ -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if and $kafkaConfig.enabled (eq $kafkaConfig.authentication.type "iam") -}}
    {{- /* TODO: This `disableAutoJarCopy` is currently broken. The authentication
           settings are not propagated through the `kafka.config` template. Although
           this should be fixed, doing so means that using this option would also
           disable the copy for the Kafka Admin pod, which would then break.

           A different solution needs to be found so that the Jar copy can be disabled
           for the main Smile CDR pod but still enabled for the Kafka Admin pod.
           END OF TODO.

           The enablement, filename and URL can be overriden if required.
           Set `disableAutoJarCopy` to true to disable copying this file. This will break
           IAM auth unless you add the file using `copyFiles`.
           This is an undocumented feature - if different files need to be added,
           the user should use the existing `copyFiles` feature instead. This override
           should only be used if troubleshooting this feature.

           This feature may need to become documented... If the cluster does not have internet
           access, then this process will not work and the user will need to use a different
           method to get the file into the pod.
           */ -}}
    {{- /* Autojar copy enabled by default */ -}}
    {{- $iamConfig := dict -}}
    {{- $_ := set $iamConfig "autoJarCopy" true -}}
    {{- $_ := set $iamConfig "copyType" "curl" -}}
    {{- $_ := set $iamConfig "fileName" "aws-msk-iam-auth-1.1.9-all.jar" -}}
    {{- $_ := set $iamConfig "url" "https://github.com/aws/aws-msk-iam-auth/releases/download/v1.1.9/aws-msk-iam-auth-1.1.9-all.jar" -}}
    {{- if hasKey $kafkaConfig.authentication "iamConfig" -}}
      {{- $iamConfig = deepCopy (mergeOverwrite $iamConfig $kafkaConfig.authentication.iamConfig ) -}}
    {{- end -}}
    {{- if $iamConfig.autoJarCopy -}}
      {{- if eq $iamConfig.copyType "curl" -}}
        {{- $url := required "You must specify a URL to copy classes files from." $iamConfig.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for classes files." $iamConfig.fileName -}}
        {{- $customerlibFileSources = append $customerlibFileSources (dict "type" "curl" "url" $url "fileName" $fileName) -}}
      {{- else if eq $iamConfig.copyType "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy IAM auth Jar file from." $iamConfig.bucket -}}
        {{- $bucketPath := required "You must specify the full S3 bucket path for the IAM auth Jar file." $iamConfig.path -}}
        {{- $customerlibFileSources = append $customerlibFileSources (dict "type" "s3" "bucket" $bucket "path" $bucketPath) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $customerlibFileSources | toYaml  -}}
{{- end -}}

{{- /*
Define Kafka consumer properties file
*/ -}}
{{- define "kafka.consumer.properties.text" -}}
  {{- $props := "# Kafka consumer properties auto generated from Helm Chart. Do not edit manually!\n" -}}
  {{- $kafkaConfig := . -}}
  {{- range $k, $v := $kafkaConfig.consumerProperties -}}
    {{- $props = printf "%s\n%s=%d" $props $k (int $v) -}}
  {{- end -}}
  {{- if eq $kafkaConfig.authentication.type "iam" -}}
    {{- $props = printf "%s\n%s=%s" $props "sasl.mechanism" "AWS_MSK_IAM" -}}
    {{- $props = printf "%s\n%s=%s" $props "sasl.jaas.config" "software.amazon.msk.auth.iam.IAMLoginModule required;" -}}
    {{- $props = printf "%s\n%s=%s" $props "sasl.client.callback.handler.class" "software.amazon.msk.auth.iam.IAMClientCallbackHandler" -}}
  {{- end -}}
  {{- $props -}}
{{- end -}}

{{- /*
Define Kafka producer properties file
*/ -}}
{{- define "kafka.producer.properties.text" -}}
  {{- $props := "# Kafka producer properties auto generated from Helm Chart. Do not edit manually!\n" -}}
  {{- $kafkaConfig := . -}}
  {{- range $k, $v := $kafkaConfig.producerProperties -}}
    {{- $props = printf "%s\n%s=%d" $props $k (int $v) -}}
  {{- end -}}
  {{- if eq $kafkaConfig.authentication.type "iam" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.mechanism" "AWS_MSK_IAM" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.jaas.config" "software.amazon.msk.auth.iam.IAMLoginModule required;" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.client.callback.handler.class" "software.amazon.msk.auth.iam.IAMClientCallbackHandler" -}}
  {{- end -}}
  {{- $props -}}
{{- end -}}
