{{- /* Keycloak Volumes Helper
    This Helper Template is used to generate volume and volumeMount` lists
    for any pods that require.

     */ -}}

{{- define "keycloak.volumes" -}}
  {{- $volumes := ( include "keycloak.fileVolumes" . | fromYamlArray ) -}}
  {{- with ( include "sdhCommon.sscsi.volumes" . | fromYamlArray ) -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- /* Include global extra volumes */ -}}
  {{- with .Values.extraVolumes -}}
    {{- $volumes = concat $volumes . -}}
  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- define "keycloak.volumeMounts" -}}
  {{- $volumeMounts := ( include "keycloak.fileVolumeMounts" . | fromYamlArray ) -}}
  {{- with ( include "sdhCommon.sscsi.volumeMounts" . | fromYamlArray ) -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{ end }}
  {{- /* Include global extra volume mounts */ -}}
  {{- with .Values.extraVolumeMounts -}}
    {{- $volumeMounts = concat $volumeMounts . -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}
