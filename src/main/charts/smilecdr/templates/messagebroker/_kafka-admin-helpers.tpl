{{/*
Common labels for Kafka Admin pod
*/}}
{{- define "kafka.admin.labels" -}}
helm.sh/chart: {{ include "smilecdr.chart" . }}
{{ include "kafka.admin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels -}}
{{ with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end -}}
{{- end }}

{{/*
Selector labels for Kafka Admin pod
*/}}
{{- define "kafka.admin.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-kafka-admin" (include "smilecdr.name" .)  }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- /*
Define env vars that will be used for Kafka certificate
passwords
*/ -}}
{{- define "kafka.admin.envVars" -}}
  {{- $envVars := (include "kafka.envVars" . | fromYamlArray) -}}
  {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}

  {{- /* TODO: Add this IAM file definition to the generic kafka config */ -}}
  {{- $envVars = append $envVars (dict "name" "CLASSPATH" "value" "/opt/kafka/classes/aws-msk-iam-auth-1.1.9-all.jar") -}}

  {{- $envVars | toYaml -}}
{{- end -}}

{{/* Define init containers for Kafka admin pod
     (Very different to Smile CDR pod init requirements)
     */}}
{{- define "kafka.admin.initContainers" -}}
  {{- $initContainers := list -}}

  {{- /* Set up config for initContainers */ -}}
  {{- $s3ContainerSpec := dict -}}
  {{- $curlContainerSpec := dict -}}

  {{- $defaultResources := dict -}}
  {{- $_ := set $defaultResources "requests" (dict "cpu" "500m" "memory" "500Mi") -}}
  {{- $_ := set $defaultResources "limits" (dict "cpu" "500m" "memory" "500Mi") -}}

  {{- $s3Config := ((.Values.copyFiles).config).s3 -}}
  {{- $defaultS3ImageTag := "2.11.25" -}}
  {{- $defaultS3ImageRepo := "amazon/aws-cli" -}}
  {{- $defaultS3ImageUser := 1000 -}}
  {{- $_ := set $s3ContainerSpec "image" (printf "%s:%s" (default $defaultS3ImageRepo $s3Config.repository) (default $defaultS3ImageTag $s3Config.tag)) -}}
  {{- $_ := set $s3ContainerSpec "imagePullPolicy" (default "IfNotPresent" $s3Config.imagePullPolicy) -}}
  {{- $_ := set $s3ContainerSpec "securityContext" (mergeOverwrite (deepCopy .Values.securityContext) (default (dict "runAsUser" $defaultS3ImageUser) $s3Config.securityContext)) -}}
  {{- $_ := set $s3ContainerSpec "resources" (default $defaultResources $s3Config.resources) -}}

  {{- $curlConfig := ((.Values.copyFiles).config).curl -}}
  {{- $defaultCurlImageTag := "8.1.2" -}}
  {{- $defaultCurlImageRepo := "curlimages/curl" -}}
  {{- $defaultCurlImageUser := 100 -}}
  {{- $_ := set $curlContainerSpec "image" (printf "%s:%s" (default $defaultCurlImageRepo $curlConfig.repository) (default $defaultCurlImageTag $curlConfig.tag)) -}}
  {{- $_ := set $curlContainerSpec "imagePullPolicy" (default "IfNotPresent" $curlConfig.imagePullPolicy) -}}
  {{- $_ := set $curlContainerSpec "securityContext" (mergeOverwrite (deepCopy .Values.securityContext) (default (dict "runAsUser" $defaultCurlImageUser) $curlConfig.securityContext)) -}}
  {{- $_ := set $curlContainerSpec "resources" (default $defaultResources $curlConfig.resources) -}}

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
      {{- $containerSpec := deepCopy (omit $s3ContainerSpec "repository" "tag") -}}
      {{- $_ := set $containerSpec "name" "init-pull-classpath-s3" -}}
      {{- $_ := set $containerSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/admin-volumes/classpath/" )  -}}
      {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "admin-classpath" "mountPath" "/tmp/admin-volumes/classpath/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
      {{- $initContainers = append $initContainers $containerSpec -}}
    {{- else if eq $v.type "curl" -}}
      {{- $url := required "You must specify a URL to copy classpath files from." $v.url -}}
      {{- $fileName := required "You must specify a destination `fileName` for classpath files." $v.fileName -}}
      {{- $fileFullPath := printf "/tmp/admin-volumes/classpath/%s" $fileName -}}
      {{- $containerSpec := deepCopy (omit $curlContainerSpec "repository" "tag") -}}
      {{- $_ := set $containerSpec "name" "init-pull-classpath-curl" -}}
      {{- $_ := set $containerSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
      {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "admin-classpath" "mountPath" "/tmp/admin-volumes/classpath/")) -}}
      {{- $initContainers = append $initContainers $containerSpec -}}
    {{- else -}}
      {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
    {{- end -}}
  {{- end -}}
  {{- $initContainers | toYaml -}}
{{- end -}}

{{- define "kafka.admin.volumes" -}}
  {{- $volumes := list -}}
  {{- $volumes = concat $volumes (include "kafka.certificate.volumes" . | fromYamlArray) -}}
  {{- $classpathVolume := dict "name" "admin-classpath" -}}
  {{- $_ := set $classpathVolume "emptyDir" (dict "sizeLimit" "20Mi") -}}
  {{- $volumes = append $volumes $classpathVolume -}}


  {{- $classpathFileSources := include "kafka.customerlib.sources" . | fromYamlArray -}}
  {{- if gt (len $classpathFileSources) 0 -}}
    {{- $hasS3Sources := false -}}
    {{- range $v := $classpathFileSources -}}
      {{- if eq $v.type "s3" -}}
        {{- $hasS3Sources = true -}}
      {{- end -}}
    {{- end -}}
    {{- if $hasS3Sources -}}
      {{- $awsCliVolume := dict "name" "aws-cli" -}}
      {{- $_ := set $awsCliVolume "emptyDir" (dict "sizeLimit" "1Mi") -}}
      {{- $volumes = append $volumes $awsCliVolume -}}
    {{- end -}}
  {{- end -}}

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

{{- define "kafka.admin.config" -}}
  {{- $kafkaAdminConfig := dict -}}
  {{- $kafkaEnabled := ternary true false (eq ((include "kafka.enabled" . ) | trim ) "true") -}}

  {{- if and $kafkaEnabled (.Values.messageBroker.adminPod).enabled -}}
    {{- $_ := set $kafkaAdminConfig "enabled" "true" -}}
    {{- $kafkaAdminImageRepo := "" -}}
    {{- $kafkaAdminImageTag := "" -}}
    {{- $strimziConfig := (include "kafka.strimzi.config" . | fromYaml) -}}
      {{- if $strimziConfig.enabled -}}
        {{- $kafkaAdminImageRepo = (default "quay.io/strimzi/kafka" (.Values.messageBroker.adminPod.image).repository) -}}
        {{- $kafkaAdminImageTag = (default "0.33.2-kafka-3.4.0" (.Values.messageBroker.adminPod.image).image) -}}
      {{- else -}}
        {{- /* Continue to use Strimzi image until we research using Bitnami or something else */ -}}
        {{- /* $kafkaAdminImageRepo = (default "public.ecr.aws/bitnami/kafka" (.Values.messageBroker.adminPod.spec).repo) -}}
        {{- $kafkaAdminImageTag = (default "3.5.1" (.Values.messageBroker.adminPod.spec).image) */ -}}
        {{- $kafkaAdminImageRepo = (default "quay.io/strimzi/kafka" (.Values.messageBroker.adminPod.image).repository) -}}
        {{- $kafkaAdminImageTag = (default "0.33.2-kafka-3.4.0" (.Values.messageBroker.adminPod.image).image) -}}
      {{- end -}}
    {{- $_ := set $kafkaAdminConfig "image" (printf "%s:%s" $kafkaAdminImageRepo $kafkaAdminImageTag )  -}}
  {{- end -}}
  {{- $kafkaAdminConfig | toYaml -}}
{{- end -}}
