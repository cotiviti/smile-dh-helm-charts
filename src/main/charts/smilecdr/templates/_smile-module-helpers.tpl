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

  {{- $modules := omit $.Values.modules "usedefaultmodules" -}}
  {{- $usedefaults := $.Values.modules.usedefaultmodules -}}
  {{- range $k, $v := $.Values.externalModuleDefinitions -}}
    {{/* This autodetects if it's a file that exists (Only relevant for default
    modules or when --include-files gets implemented in Helm).
    If it's nota file, we can assume it's the actual config, passed in by --set-file
    TODO: Add a warning if it's not a string. */}}
    {{- if ( $.Files.Get $v ) -}}
      {{- if not ( and ( eq $k "default" ) ( not $usedefaults )) -}}
        {{- $_ := merge $modules $modules ( $.Files.Get $v | fromYaml ) -}}
      {{- end -}}
    {{- else -}}
      {{- range $k2, $v2 := ( $v | fromYaml ) -}}
        {{- $_ := merge $modules $modules $v2 -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

{{- range $k, $v := $modules -}}
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
