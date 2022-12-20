{{/*
These helper templates are used to help import files into the environment
using ConfigMaps
*/}}

{{- /*
This template helps create a configMap for each file that is defined in the
.Values.mappedFiles section.
It expects that there should also be a .Values.mappedFiles.filename.data section
that contains the file contents, as passed in by the --set-file helm install option.
If a file is added to mappedFiles, but does not have a `data` key, then it will be
quietly ignored.
*/ -}}
{{- define "smilecdr.fileConfigMaps" -}}
{{- $fileCfgMaps := list -}}
{{- if gt (len .Values.mappedFiles) 0 -}}
  {{- range $k, $v := .Values.mappedFiles -}}
    {{- if hasKey $v "data" -}}
      {{- $fileCfgMaps = append $fileCfgMaps (dict "name" ( $k ) "data" $v.data "hash" ( sha256sum $v.data )) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if gt (len $fileCfgMaps) 0 -}}
  {{- printf "list:\n%v" ($fileCfgMaps | toYaml) -}}
{{- end -}}
{{- end -}}

{{/*
Define fileVolumes for all mapped files
*/}}
{{ define "smilecdr.fileVolumes" }}
  {{- $fileVolumes := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $cmName := printf "%s-scdr-%s" $.Release.Name ($k | replace "." "-") -}}
      {{- if and $.Values.autoDeploy (hasKey $v "data") -}}
        {{- $cmName = printf "%s-%s" $cmName (sha256sum ($v.data)) -}}
      {{- end -}}
      {{- $fileVolume := dict "name" ($k | replace "." "-") -}}
      {{- $_ := set $fileVolume "configMap" (dict "name" $cmName) -}}
      {{- $fileVolumes = append $fileVolumes $fileVolume -}}
    {{- end -}}
  {{- end -}}
  {{- dict "list" $fileVolumes | toYaml -}}
{{- end -}}

{{/*
Define fileVolumeMounts for all mapped files
*/}}
{{ define "smilecdr.fileVolumeMounts" }}
  {{- $fileVolumeMounts := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $fileVolumeMount := dict "name" ($k | replace "." "-") -}}
      {{- $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $v.path) $k) -}}
      {{- $_ := set $fileVolumeMount "subPath" $k -}}
      {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- dict "list" $fileVolumeMounts | toYaml -}}
{{ end }}
