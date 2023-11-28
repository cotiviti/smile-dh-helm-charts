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
  {{- /* TODO: we do not need release name in these identifiers. It's just internal
      to the pod. */ -}}
  {{- $configMapVolume := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" (printf "%s-%s" .Release.Name .Values.configMapResourceSuffix)) -}}
  {{- $volumes = append $volumes $configMapVolume -}}
  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
    {{- $tmpVolume := dict "name" "scdr-volume-tmp" -}}
    {{- $_ := set $tmpVolume "emptyDir" (dict "sizeLimit" "1Mi") -}}
    {{- $volumes = append $volumes $tmpVolume -}}
    {{- $logsVolume := dict "name" "scdr-volume-log" -}}
    {{- $_ := set $logsVolume "emptyDir" (dict "sizeLimit" .Values.logsDirSize ) -}}
    {{- $volumes = append $volumes $logsVolume -}}
    {{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
    {{- $amqConfig := (include "messagebroker.amq.config" . | fromYaml) -}}
    {{- if and (not $kafkaConfig.enabled) (not $amqConfig.enabled) -}}
      {{- $amqVolume := dict "name" "scdr-volume-amq" -}}
      {{- $_ := set $amqVolume "emptyDir" (dict "sizeLimit" "10Mi") -}}
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
  {{- $configMapVolumeMount := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolumeMount "mountPath" "/home/smile/smilecdr/classes/cdr-config-Master.properties" -}}
  {{- $_ := set $configMapVolumeMount "subPath" "cdr-config-Master.properties" -}}
  {{- $volumeMounts = append $volumeMounts $configMapVolumeMount -}}
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
