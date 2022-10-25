{{/*
Extract and define details of module configurations for use elsewhere in the chart.
*/}}
{{/*
Define module endpoints
*IMPORTANT* If using this in a parseable manner (say, within a range) you need
to import it and pipe that through the fromYaml function like so:
{{- range $k, $v := include "smilecdr.services" . | fromYaml }}
*/}}
{{- define "smilecdr.fileVolumes" -}}

{{- range $k, $v := .Values.mappedFiles -}}
{{- if eq $v.type "configMap" -}}
- name: {{ $k | replace "." "-" }}
  configMap:
    name: {{ $.Release.Name }}-{{ $v.configMapBaseName }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "smilecdr.fileVolumeMounts" -}}

{{- range $k, $v := .Values.mappedFiles -}}
- name: {{ $k | replace "." "-" }}
  mountPath: {{ $v.path }}/{{ $k }}
  subPath: {{ $k }}
{{- end -}}
{{- end -}}