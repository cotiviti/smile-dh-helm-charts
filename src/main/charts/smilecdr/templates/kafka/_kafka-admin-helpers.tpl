{{- /*
Define env vars that will be used for Kafka certificate
passwords
*/ -}}
{{- define "kafka.admin.envVars" -}}
  {{- $envVars := (include "kafka.envVars" . | fromYamlArray) -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}

  {{- /* TODO: Add this IAM file definition to the generic kafka config */ -}}
  {{- $envVars = append $envVars (dict "name" "CLASSPATH" "value" "/opt/kafka/classes/aws-msk-iam-auth-1.1.6-all.jar") -}}

  {{- $envVars | toYaml -}}
{{- end -}}

{{/* Define init containers for Kafka admin pod
     (Very different to Smile CDR pod init requirements)
     */}}
{{- define "kafka.admin.initContainers" -}}
  {{- $initContainers := list -}}

  {{- /* Admin container only needs files copied to classpath right now */ -}}
  {{- $classpathDir := "/opt/kafka/bin" -}}
  {{- $initContainerResources := (dict "requests" (dict "cpu" "500m" "memory" "500Mi")) -}}
  {{- $_ := set $initContainerResources "limits" (dict "cpu" "500m" "memory" "500Mi") -}}

  {{- /* The libs needed by Kafka for the current configuration */ -}}
  {{- $classpathFileSources := include "kafka.customerlib.sources" . | fromYamlArray -}}

  {{- range $v := $classpathFileSources -}}
    {{- if eq $v.type "s3" -}}
      {{- $bucket := required "You must specify an S3 bucket to copy classpath files from." $v.bucket -}}
      {{- $bucketPath := required "You must specify an S3 bucket path to copy classpath files from." $v.path -}}
      {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
      {{- $imageSpec := dict "name" "init-pull-classpath-s3" -}}
      {{- $_ := set $imageSpec "image" "public.ecr.aws/aws-cli/aws-cli" -}}
      {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
      {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/admin-volumes/classpath/" "--recursive" )  -}}
      {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "admin-classpath" "mountPath" "/tmp/admin-volumes/classpath/")) -}}
      {{- $initContainers = append $initContainers $imageSpec -}}
    {{- else if eq $v.type "curl" -}}
      {{- $url := required "You must specify a URL to copy classpath files from." $v.url -}}
      {{- $fileName := required "You must specify a destination `fileName` for classpath files." $v.fileName -}}
      {{- $fileFullPath := printf "/tmp/admin-volumes/classpath/%s" $fileName -}}
      {{- $imageSpec := dict "name" "init-pull-classpath-curl" -}}
      {{- $_ := set $imageSpec "image" "curlimages/curl" -}}
      {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
      {{- $_ := set $imageSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
      {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "admin-classpath" "mountPath" "/tmp/admin-volumes/classpath/")) -}}
      {{- $initContainers = append $initContainers $imageSpec -}}
    {{- else -}}
      {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
    {{- end -}}
  {{- end -}}
  {{- $initContainers | toYaml -}}
{{- end -}}

{{- define "kafka.admin.volumes" -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- $volumes := list -}}
  {{- $volumes = concat $volumes (include "kafka.certificate.volumes" . | fromYamlArray) -}}
  {{- $classpathVolume := dict "name" "admin-classpath" -}}
  {{- $_ := set $classpathVolume "emptyDir" (dict "sizeLimit" "20Mi") -}}
  {{- $volumes = append $volumes $classpathVolume -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{ define "kafka.admin.volumeMounts" }}
  {{- $volumeMounts := list -}}
  {{- $volumeMounts = concat $volumeMounts (include "kafka.certificate.volumeMounts" . | fromYamlArray) -}}
  {{- $classpathVolumeMount := dict "name" "admin-classpath" -}}
  {{- $_ := set $classpathVolumeMount "mountPath" "/opt/kafka/classes" -}}
  {{- $volumeMounts = append $volumeMounts $classpathVolumeMount -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}

{{- /*
Define Kafka client properties file for admin pod
*/ -}}
{{- define "kafka.admin.consumer.properties.text" -}}
  {{- $props := "# Kafka consumer properties auto generated from Helm Chart. Do not edit manually!\n" -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if $kafkaConfig.enabled -}}
    {{- if eq $kafkaConfig.connection.type "tls" -}}
      {{- if eq $kafkaConfig.authentication.type "iam" -}}
        {{- $props = printf "%s\n%s=%s" $props "security.protocol" "SASL_SSL" -}}
      {{- else -}}
        {{- $props = printf "%s\n%s=%s" $props "security.protocol" "SSL" -}}
      {{- end -}}
      {{- if not $kafkaConfig.publicca -}}
        {{- $props = printf "%s\n%s=%s" $props "ssl.truststore.location" "/home/smile/smilecdr/classes/client_certificates/kafka-ca-cert.p12" -}}
        {{- $props = printf "%s\n%s=%s" $props "ssl.truststore.password" "${KAFKA_BROKER_CA_CERT_PWD}" -}}
      {{- end -}}
    {{- end -}}
    {{- if eq $kafkaConfig.authentication.type "tls" -}}
      {{- $props = printf "%s\n%s=%s" $props "ssl.keystore.location" "/home/smile/smilecdr/classes/client_certificates/kafka-client-cert.p12" -}}
      {{- $props = printf "%s\n%s=%s" $props "ssl.keystore.password" "${KAFKA_CLIENT_CERT_PWD}" -}}
    {{- end -}}
    {{- if eq $kafkaConfig.authentication.type "iam" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.mechanism" "AWS_MSK_IAM" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.jaas.config" "software.amazon.msk.auth.iam.IAMLoginModule required;" -}}
      {{- $props = printf "%s\n%s=%s" $props "sasl.client.callback.handler.class" "software.amazon.msk.auth.iam.IAMClientCallbackHandler" -}}
    {{- end -}}
  {{- end -}}
  {{- $props -}}
{{- end -}}
