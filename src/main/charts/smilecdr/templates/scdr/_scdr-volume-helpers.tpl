{{/*
Define volumes and volume mounts based on combining:
* Generated fileVolumes
* Smile CDR properties file
* Secrets Store CSI volumes
* Any others can be added later
*/}}

{{- define "smilecdr.volumes" -}}
  {{- $volumes := ( include "smilecdr.fileVolumes" . | fromYaml ).list -}}
  {{- with ( include "sscsi.volumes" . | fromYaml ).list -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- $configMapVolume := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" (printf "%s-scdr-%s-node%s" .Release.Name (include "smilecdr.nodeId" . | lower) (include "smilecdr.cdrConfigDataHashSuffix" . ) )) -}}
  {{- $volumes = concat $volumes (list ($configMapVolume)) -}}
  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
  {{- $tmpVolume := dict "name" "scdr-volume-tmp" -}}
  {{- $_ := set $tmpVolume "emptyDir" (dict "sizeLimit" "1Mi") -}}
  {{- $volumes = concat $volumes (list ($tmpVolume)) -}}
  {{- $logsVolume := dict "name" "scdr-volume-log" -}}
  {{- $_ := set $logsVolume "emptyDir" (dict "sizeLimit" (include "smilecdr.nodeSettings" . | fromYaml).logsDirSize ) -}}
  {{- $volumes = concat $volumes (list ($logsVolume)) -}}
  {{- if not (or .Values.messageBroker.strimzi.enabled .Values.messageBroker.external.enabled) -}}
    {{- $amqVolume := dict "name" "scdr-volume-amq" -}}
    {{- $_ := set $amqVolume "emptyDir" (dict "sizeLimit" "10Mi") -}}
    {{- $volumes = concat $volumes (list ($amqVolume)) -}}
  {{- end -}}
  {{- end -}}
  {{ range $v := $volumes }}
    {{- printf "- %v\n" ($v | toYaml | nindent 2 | trim ) -}}
  {{ end }}
{{- end -}}

{{ define "smilecdr.volumeMounts" }}
  {{- $volumeMounts := ( include "smilecdr.fileVolumeMounts" . | fromYaml ).list -}}
  {{- with ( include "sscsi.volumeMounts" . | fromYaml ).list -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{ end }}
  {{- $configMapVolumeMount := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolumeMount "mountPath" "/home/smile/smilecdr/classes/cdr-config-Master.properties" -}}
  {{- $_ := set $configMapVolumeMount "subPath" "cdr-config-Master.properties" -}}
  {{- $volumeMounts = concat $volumeMounts (list $configMapVolumeMount) -}}
  {{- if eq true .Values.securityContext.readOnlyRootFilesystem -}}
  {{- $tmpVolumeMount := dict "name" "scdr-volume-tmp" -}}
  {{- $_ := set $tmpVolumeMount "mountPath" "/home/smile/smilecdr/tmp" -}}
  {{- $volumeMounts = concat $volumeMounts (list ($tmpVolumeMount)) -}}
  {{- $logsVolumeMount := dict "name" "scdr-volume-log" -}}
  {{- $_ := set $logsVolumeMount "mountPath" "/home/smile/smilecdr/log" -}}
  {{- $volumeMounts = concat $volumeMounts (list ($logsVolumeMount)) -}}
  {{- if not (or .Values.messageBroker.strimzi.enabled .Values.messageBroker.external.enabled) -}}
    {{- $amqVolumeMount := dict "name" "scdr-volume-amq" -}}
    {{- $_ := set $amqVolumeMount "mountPath" "/home/smile/smilecdr/activemq-data" -}}
    {{- $volumeMounts = concat $volumeMounts (list ($amqVolumeMount)) -}}
  {{- end -}}
  {{- end -}}
  {{ range $v := $volumeMounts }}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{ end }}
{{- end -}}
