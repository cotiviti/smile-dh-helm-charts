{{/*
Extract and define details of module configurations for use elsewhere in the chart.
*/}}
{{/*
Define module endpoints
*IMPORTANT* If using this in a parseable manner (say, within a range) you need
to import it and pipe that through the fromYaml function like so:
{{- range $k, $v := include "smilecdr.services" . | fromYaml }}
*/}}
{{- define "smilecdr.services" -}}

{{- range $k, $v := .Values.modules -}}
{{- if $v.enabled -}}
{{- if (($v.service).enabled) -}}
{{/* Copying each module key, if enabled and if it has an enabled endpoint. */}}
{{ $k -}}:
{{- /* Derive & define new config for module. */}}
  contextPath: {{ $v.config.context_path }}
  fullPath: {{ (default "/" $.Values.specs.rootPath) }}{{ $v.config.context_path }}
  svcName: {{ $v.service.svcName }}
  port: {{ $v.config.port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
