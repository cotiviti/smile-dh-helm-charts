{{/*
Define volumes and volume mounts based on combining:
* Generated fileVolumes
* SmileCDR properties file
* Secrets Store CSI volumes
* Any others can be added later
*/}}

{{- define "smilecdr.volumes" -}}
  {{- $volumes := ( include "smilecdr.fileVolumes" . | fromYaml ).list -}}
  {{- with ( include "sscsi.volume" . | fromYaml ).list -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- $configMapVolume := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolume "configMap" (dict "name" (printf "%s-scdr%s" .Release.Name (include "smilecdr.cdrConfigDataHash" . ) )) -}}
  {{- $volumes = concat $volumes (list ($configMapVolume)) -}}
  {{ range $v := $volumes }}
    {{- printf "- %v\n" ($v | toYaml | nindent 2 | trim ) -}}
  {{ end }}
{{- end -}}

{{ define "smilecdr.volumeMounts" }}
  {{- $volumeMounts := ( include "smilecdr.fileVolumeMounts" . | fromYaml ).list -}}
  {{- with ( include "sscsi.volumeMount" . | fromYaml ).list -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{ end }}
  {{- $configMapVolumeMount := dict "name" (printf "scdr-config-%s" .Release.Name) -}}
  {{- $_ := set $configMapVolumeMount "mountPath" "/home/smile/smilecdr/classes/cdr-config-Master.properties" -}}
  {{- $_ := set $configMapVolumeMount "subPath" "cdr-config-Master.properties" -}}
  {{- $volumeMounts = concat $volumeMounts (list $configMapVolumeMount) -}}
  {{ range $v := $volumeMounts }}
    {{- printf "- %v\n" ($v | toYaml | indent 2 | trim) -}}
  {{ end }}
{{- end -}}
