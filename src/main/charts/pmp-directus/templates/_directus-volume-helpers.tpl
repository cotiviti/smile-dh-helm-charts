{{- /* Directus Volumes Helper
    This Helper Template is used to generate volume and volumeMount` lists
    for any pods that require.

     */ -}}

{{- define "directus.volumes" -}}
  {{- $volumes := ( include "directus.fileVolumes" . | fromYamlArray ) -}}
  {{- with ( include "sdhCommon.sscsi.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- /* Include global extra volumes */ -}}
  {{- with .Values.extraVolumes -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- define "directus.volumeMounts" -}}
  {{- $volumeMounts := ( include "directus.fileVolumeMounts" . | fromYamlArray ) -}}
  {{- with ( include "sdhCommon.sscsi.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{ end }}
  {{- /* Include global extra volume mounts */ -}}
  {{- with .Values.extraVolumeMounts -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}
