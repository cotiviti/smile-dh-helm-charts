{{- /* PMP Volumes Helper
    This Helper Template is used to generate volume and volumeMount` lists
    for any pods that require.

    Takes a sructured object as a parameter:
    name: component name
    value: component config
    Chart: chart values ($.Chart)
    Values: chart values ($.Values)
    Release: Chart release ($.Release)


    Includes:
    * sscsi mounts for *service pods
    * config.json mounts for portal apps
     */ -}}

{{- define "component.volumes" -}}
  {{- $volumes := list -}}
  {{- $currentComponentName := ternary .componentName nil (not (eq .componentName nil)) -}}
  {{- if hasKey .Values "config" -}}
    {{- $currentComponentConfig := .Values.config -}}
    {{- $configFormat := default "json" $currentComponentConfig.type -}}
    {{- if eq $configFormat "json" -}}
      {{- $configMap := ( include "component.configMap" . | fromYaml ) -}}
      {{- $configMapVolume := dict "name" "config-json" -}}
      {{- $_ := set $configMapVolume "configMap" (dict "name" $configMap.configMapName) -}}
      {{- $volumes = append $volumes $configMapVolume -}}
    {{- else -}}
      {{- fail (printf "Config type `%s` in component `%s` is not supported." $configFormat $currentComponentName) -}}
    {{- end -}}
  {{- end -}}
  {{- if eq ((include "sdhCommon.sscsi.enabled" . ) | trim ) "true" -}}
  {{- /* if (include "sdhCommon.sscsi.enabled" . ) | fromYaml */ -}}
    {{- $volumes = concat $volumes (include "sdhCommon.sscsi.volumes" . | fromYamlArray) -}}
  {{- end -}}

  {{- $volumes | toYaml -}}
{{- end -}}

{{- define "component.volumeMounts" -}}
  {{- $volumeMounts := list -}}
  {{- $currentComponentName := ternary .componentName nil (not (eq .componentName nil)) -}}
  {{- if hasKey .Values "config" -}}
    {{- $currentComponentConfig := .Values.config -}}
    {{- $configFormat := default "json" $currentComponentConfig.type -}}
    {{- if eq $configFormat "json" -}}
      {{- $configMapVolumeMount := dict "name" "config-json" -}}
      {{- $_ := set $configMapVolumeMount "mountPath" (printf "%s/%s" $currentComponentConfig.filePath $currentComponentConfig.fileName ) -}}
      {{- $_ := set $configMapVolumeMount "subPath" $currentComponentConfig.fileName -}}
      {{- $volumeMounts = append $volumeMounts $configMapVolumeMount -}}
    {{- else -}}
      {{- fail (printf "Config type `%s` in component `%s` is not supported." $configFormat $currentComponentName) -}}
    {{- end -}}
  {{- end -}}
  {{- if eq ((include "sdhCommon.sscsi.enabled" . ) | trim ) "true" -}}
  {{- /* if (include "sdhCommon.sscsi.enabled" . ) | fromYaml */ -}}
    {{- $volumeMounts = concat $volumeMounts (include "sdhCommon.sscsi.volumeMounts" . | fromYamlArray) -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}
