{{/*
These helper templates are used to help import files into the environment
using ConfigMaps
*/}}

{{- /*
This template generates the final list of mapped files by combinging some
predefined mapped files with those passed in via .values.mappedFiles, giving
priority to the latter.
This is used when generating congfig maps and for mounting them into pods.
*/ -}}
{{- define "directus.mappedFiles" -}}
  {{- $mappedFiles := dict -}}
  {{/* Add initialization files to mappedFiles object */}}
  {{- $_ := set $mappedFiles "20230321A-pmp-updates.js" (dict "path" "/directus/extensions/migrations" "data" ($.Files.Get "directus-init/20230321A-pmp-updates.js")) -}}
  {{- $_ := set $mappedFiles "pmp-items.json" (dict "path" "/directus" "data" ($.Files.Get "directus-init/pmp-items.json")) -}}
  {{- $_ := set $mappedFiles "pmp-schema.yaml" (dict "path" "/directus" "data" ($.Files.Get "directus-init/pmp-schema.yaml")) -}}
  {{- (mergeOverwrite $mappedFiles .Values.mappedFiles) | toYaml -}}
{{- end -}}

{{- /*
This template helps create a configMap for each file that is defined in the
.Values.mappedFiles section.
It expects that there should also be a .Values.mappedFiles.filename.data section
that contains the file contents, as passed in by the --set-file helm install option.
If a file is added to mappedFiles, but does not have a `data` key, then it will be
quietly ignored.
*/ -}}
{{- define "directus.fileConfigMaps" -}}
{{- $fileCfgMaps := list -}}
{{- $mappedFiles := include "directus.mappedFiles" . | fromYaml -}}
{{- if gt (len $mappedFiles) 0 -}}
  {{- range $k, $v := $mappedFiles -}}
    {{- if hasKey $v "data" -}}
      {{- $fileCfgMaps = append $fileCfgMaps (dict "name" ( $k ) "data" $v.data "hash" ( sha256sum $v.data )) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $fileCfgMaps | toYaml -}}
{{- end -}}

{{/*
Define fileVolumes for all mapped files
*/}}
{{ define "directus.fileVolumes" }}
  {{- $fileVolumes := list -}}
  {{- $mappedFiles := include "directus.mappedFiles" . | fromYaml -}}
  {{- if gt (len $mappedFiles) 0 -}}
    {{- range $k, $v := $mappedFiles -}}
      {{- $cmName := printf "%s-directus-%s" $.Release.Name ($k | lower | replace "." "-") -}}
      {{- if and $.Values.autoDeploy (hasKey $v "data") -}}
        {{- $cmName = printf "%s-%s" $cmName (sha256sum ($v.data)) -}}
      {{- end -}}
      {{- $fileVolume := dict "name" ($k | lower | replace "." "-") -}}
      {{- $_ := set $fileVolume "configMap" (dict "name" $cmName) -}}
      {{- $fileVolumes = append $fileVolumes $fileVolume -}}
    {{- end -}}
  {{- end -}}
  {{- $fileVolumes | toYaml -}}
{{- end -}}

{{/*
Define fileVolumeMounts for all mapped files
*/}}
{{ define "directus.fileVolumeMounts" }}
  {{- $fileVolumeMounts := list -}}
  {{- $mappedFiles := include "directus.mappedFiles" . | fromYaml -}}
  {{- if gt (len $mappedFiles) 0 -}}
    {{- range $k, $v := $mappedFiles -}}
      {{- $fileVolumeMount := dict "name" ($k | lower | replace "." "-") -}}
      {{- $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/directus/" $v.path) $k) -}}
      {{- $_ := set $fileVolumeMount "subPath" $k -}}
      {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- $fileVolumeMounts | toYaml -}}
{{ end }}
