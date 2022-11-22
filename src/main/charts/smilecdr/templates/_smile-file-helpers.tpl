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
{{ if eq $v.type "configMap" }}
- name: {{ $k | replace "." "-" }}
  configMap:
    name: {{ $.Release.Name }}-{{ $v.configMapBaseName }}
{{ end }}
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
  mountPath: {{ $v.path }}/{{ $k }}
  subPath: {{ $k }}
{{ end }}
{{ else }}
  []
{{ end }}
{{ end }}
