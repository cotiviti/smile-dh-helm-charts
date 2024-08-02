{{/*
Define volumes and volume mounts based on combining:
* Generated fileVolumes
* Smile CDR properties file
* Secrets Store CSI volumes
* Any others can be added later
*/}}

{{- define "smilecdr.volumes" -}}
  {{- $volumes := ( include "smilecdr.fileVolumes" . | fromYamlArray ) -}}
  {{- with ( include "sscsi.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- /* Include any volumes required by Kafka (Certificates and settings files) */ -}}
  {{- with ( include "kafka.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- /* Include any volumes required by observability addons */ -}}
  {{- with ( include "observability.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}

  {{- /* Include any volumes required by TLS configurations. (Currently only for cert-manager generated keystores ) */ -}}
  {{- with ( include "certmanager.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}

  {{- /* Include volume for CDR license */ -}}
  {{- $licenseConfig := (include "smilecdr.license" . | fromYaml) -}}
  {{- if and $licenseConfig.secret $licenseConfig.secret.volumeMap -}}
    {{- $volumes = concat $volumes $licenseConfig.secret.volumeMap -}}
  {{- end -}}

  {{- /* Include volume for extraSecrets */ -}}
  {{- $extraSecrets := (include "smilecdr.extraSecrets" . | fromYaml) -}}
  {{- range $extraSecret :=  $extraSecrets.secrets -}}
    {{- range $volume := $extraSecret.volumeMap -}}
      {{- $volumes = append $volumes $volume -}}
    {{- end -}}
  {{- end -}}

  {{- /* Include any volumes required by custom logging configuraions */ -}}
  {{- /* with ( include "logging.logback.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end */ -}}
  {{- /* TODO: we do not need release name in these identifiers. It's just internal
      to the pod. */ -}}
  {{- $configMapVolume := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" (printf "%s-%s" .Release.Name .Values.configMapResourceSuffix)) -}}
  {{- $volumes = append $volumes $configMapVolume -}}

  {{- /* Helm Specific smileutil command */ -}}
  {{- $configMapVolume := dict "name" "scdr-smileutil" -}}
  {{- $cmName := printf "%s-scdr-smileutil" .Release.Name -}}
  {{- if $.Values.autoDeploy -}}
    {{- $cmName = printf "%s-scdr-smileutil-%s" .Release.Name (sha256sum (include "smilecdr.cdrSmileutilText" .)) -}}
  {{- end -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" $cmName "defaultMode" 0770 ) -}}
  {{- $volumes = append $volumes $configMapVolume -}}

  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
    {{- $tmpVolume := dict "name" "scdr-volume-tmp" -}}
    {{- $_ := set $tmpVolume "emptyDir" (dict "sizeLimit" (default "1Mi" (((.Values.volumeConfig).cdr).tmp).size)) -}}
    {{- $volumes = append $volumes $tmpVolume -}}
    {{- $logsVolume := dict "name" "scdr-volume-log" -}}
    {{- /* TODO: Remove the logsDirSize option after deprecation period. */ -}}
    {{- /* $_ := set $logsVolume "emptyDir" (dict "sizeLimit" (default "10Gi" ((.Values.volumeConfig).logs).size)) */ -}}
    {{- $_ := set $logsVolume "emptyDir" (dict "sizeLimit" (coalesce .Values.logsDirSize (((.Values.volumeConfig).cdr).log).size "10Gi") ) -}}
    {{- $volumes = append $volumes $logsVolume -}}
    {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
    {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
    {{- if and (not $kafkaConfig.enabled) (not $amqConfig.enabled) -}}
      {{- $amqVolume := dict "name" "scdr-volume-amq" -}}
      {{- $_ := set $amqVolume "emptyDir" (dict "sizeLimit" (default "10Mi" (((.Values.volumeConfig).cdr).amq).size)) -}}
      {{- $volumes = append $volumes $amqVolume -}}
    {{- end -}}
    {{- $fileSources := (include "smilecdr.classes.sources" . | fromYamlArray ) -}}
    {{- $fileSources = concat $fileSources (include "smilecdr.customerlib.sources" . | fromYamlArray ) -}}
    {{- if gt (len $fileSources) 0 -}}
      {{- $hasS3Sources := false -}}
      {{- range $v := $fileSources -}}
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
  {{- end -}}
  {{- /* Include global extra volumes */ -}}
  {{- with .Values.extraVolumes -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{ $volumes | toYaml }}
{{- end -}}

{{ define "smilecdr.volumeMounts" }}
  {{- $volumeMounts := ( include "smilecdr.fileVolumeMounts" . | fromYamlArray ) -}}
  {{- with ( include "sscsi.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{ end }}
  {{- with ( include "kafka.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}
  {{- with ( include "observability.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}

  {{- with ( include "certmanager.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}

  {{- /* Include volumeMount for CDR license */ -}}
  {{- $licenseConfig := (include "smilecdr.license" . | fromYaml) -}}
  {{- if and $licenseConfig.secret $licenseConfig.secret.volumeMountMap -}}
    {{- $volumeMounts = concat $volumeMounts $licenseConfig.secret.volumeMountMap -}}
  {{- end -}}

  {{- /* Include volumeMounts for extraSecrets */ -}}
  {{- $extraSecrets := (include "smilecdr.extraSecrets" . | fromYaml) -}}
  {{- range $extraSecret :=  $extraSecrets.secrets -}}
    {{- range $volumeMount := $extraSecret.volumeMountMap -}}
      {{- $volumeMounts = append $volumeMounts $volumeMount -}}
    {{- end -}}
  {{- end -}}

  {{- /* with ( include "logging.logback.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end */ -}}
  {{- $configMapVolumeMount := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolumeMount "mountPath" "/home/smile/smilecdr/classes/cdr-config-Master.properties" -}}
  {{- $_ := set $configMapVolumeMount "subPath" "cdr-config-Master.properties" -}}
  {{- $volumeMounts = append $volumeMounts $configMapVolumeMount -}}

  {{- /* Helm Specific smileutil command */ -}}
  {{- $smileutilVolumeMount := dict "name" "scdr-smileutil" -}}
  {{- $_ := set $smileutilVolumeMount "mountPath" "/home/smile/smilecdr/bin/smileutil" -}}
  {{- $_ := set $smileutilVolumeMount "subPath" "smileutil" -}}
  {{- $volumeMounts = append $volumeMounts $smileutilVolumeMount -}}

  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
    {{- $tmpVolumeMount := dict "name" "scdr-volume-tmp" -}}
    {{- $_ := set $tmpVolumeMount "mountPath" "/home/smile/smilecdr/tmp" -}}
    {{- $volumeMounts = append $volumeMounts $tmpVolumeMount -}}
    {{- $logsVolumeMount := dict "name" "scdr-volume-log" -}}
    {{- $_ := set $logsVolumeMount "mountPath" "/home/smile/smilecdr/log" -}}
    {{- $volumeMounts = append $volumeMounts $logsVolumeMount -}}
    {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
    {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
    {{- if and (not $kafkaConfig.enabled) (not $amqConfig.enabled) -}}
      {{- $amqVolumeMount := dict "name" "scdr-volume-amq" -}}
      {{- $_ := set $amqVolumeMount "mountPath" "/home/smile/smilecdr/activemq-data" -}}
      {{- $volumeMounts = append $volumeMounts $amqVolumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- /* Include global extra volume mounts */ -}}
  {{- with .Values.extraVolumeMounts -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}
