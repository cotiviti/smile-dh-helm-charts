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
        {{- $_ := merge $modules ( $.Files.Get $v | fromYaml ).modules -}}
      {{- end -}}
    {{- else -}}
      {{- range $k2, $v2 := ( $v | fromYaml ) -}}
        {{- $_ := merge $modules $v2 -}}
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


{{- define "smilecdr.readinessProbe" -}}
  {{- $modules := omit $.Values.modules "usedefaultmodules" -}}
  {{- $usedefaults := $.Values.modules.usedefaultmodules -}}
  {{- range $k, $v := $.Values.externalModuleDefinitions -}}
    {{- /* This autodetects if it's a file that exists (Only relevant for default
    modules or when --include-files gets implemented in Helm).
    If it's nota file, we can assume it's the actual config, passed in by --set-file
    TODO: Add a warning if it's not a string. */ -}}
    {{- if ( $.Files.Get $v ) -}}
      {{- if not ( and ( eq $k "default" ) ( not $usedefaults )) -}}
        {{- $_ := merge $modules ( $.Files.Get $v | fromYaml ).modules -}}
      {{- end -}}
    {{- else -}}
      {{- range $k2, $v2 := ( $v | fromYaml ) -}}
        {{- $_ := merge $modules $v2 -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- range $k, $v := $modules -}}
    {{- /* If enabled and if it has an enabled endpoint. */ -}}
    {{- if $v.enabled -}}
      {{- if (($v.service).enabled) -}}
        {{- if eq $v.type "ENDPOINT_FHIR_REST_R4" -}}
          {{- /* Derive & define values for the readiness probe. */ -}}
httpGet:
  path: {{ printf "%s%s%s" (default "/" $.Values.specs.rootPath) $v.config.context_path (default "/endpoint-health" (index $v.config "endpoint_health.path" )) }}
  port: {{ $v.config.port }}
failureThreshold: 1
periodSeconds: 10
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
