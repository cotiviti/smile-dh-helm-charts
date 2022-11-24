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
    name: {{ $.Release.Name }}-scdr-{{ $k | replace "." "-" }}
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
      {{- $fileCfgMaps = append $fileCfgMaps (dict "name" ( $k | replace "." "-") "data" $v.data) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if gt (len $fileCfgMaps) 0 -}}
  {{- printf "list:\n%v" ($fileCfgMaps | toYaml) -}}
{{- end -}}
{{- end -}}
