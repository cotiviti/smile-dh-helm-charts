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
  {{- $configMapVolume := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" (printf "%s-scdr-%s-node%s" .Release.Name (include "smilecdr.nodeId" . | lower) (include "smilecdr.cdrConfigDataHashSuffix" . ) )) -}}
  {{- $volumes = append $volumes $configMapVolume -}}
  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
    {{- $tmpVolume := dict "name" "scdr-volume-tmp" -}}
    {{- $_ := set $tmpVolume "emptyDir" (dict "sizeLimit" "1Mi") -}}
    {{- $volumes = append $volumes $tmpVolume -}}
    {{- $logsVolume := dict "name" "scdr-volume-log" -}}
    {{- $_ := set $logsVolume "emptyDir" (dict "sizeLimit" (include "smilecdr.nodeSettings" . | fromYaml).logsDirSize ) -}}
    {{- $volumes = append $volumes $logsVolume -}}
    {{- if not (or .Values.messageBroker.strimzi.enabled .Values.messageBroker.external.enabled) -}}
      {{- $amqVolume := dict "name" "scdr-volume-amq" -}}
      {{- $_ := set $amqVolume "emptyDir" (dict "sizeLimit" "10Mi") -}}
      {{- $volumes = append $volumes $amqVolume -}}
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
    {{- if not (or .Values.messageBroker.strimzi.enabled .Values.messageBroker.external.enabled) -}}
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
