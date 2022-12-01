{{/*
Extract and define details of module configurations for use elsewhere in the chart.
*/}}
{{/*
Define module endpoints
*/}}
{{ define "smilecdr.fileVolumes" }}
list:
{{ if gt (len .Values.mappedFiles) 0 }}
{{ range $k, $v := .Values.mappedFiles }}
- name: {{ $k | replace "." "-" }}
  configMap:
    {{- if $.Values.autoDeploy }}
      {{- if hasKey $v "data" }}
    name: {{ $.Release.Name }}-scdr-{{ $k | replace "." "-" }}-{{ sha256sum ($v.data) }}
      {{- else }}
    name: {{ $.Release.Name }}-scdr-{{ $k | replace "." "-" }}
      {{- end }}
    {{- else }}
    name: {{ $.Release.Name }}-scdr-{{ $k | replace "." "-" }}
    {{- end }}
{{ end }}
{{ else }}
  []
{{ end }}
{{ end }}

{{ define "smilecdr.fileVolumeMounts" }}
list:
{{ if gt (len .Values.mappedFiles) 0 }}
{{ range $k, $v := .Values.mappedFiles }}
- name: {{ $k | replace "." "-" }}
  mountPath: {{ default "/home/smile/smilecdr/classes" $v.path }}/{{ $k }}
  subPath: {{ $k }}
{{ end }}
{{ else }}
  []
{{ end }}
{{ end }}

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
