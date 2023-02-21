{{/*
Depending on the Smile CDR cluster architecture being used, it only makes
sense to use certain endpoints for the readiness probe.
Due to some healthcheck endpoints not working out-of-the-box with anon
access, we had to choose a sensible default service to use for this.
Currently, the FHIR Rest Endpoint makes the most sense.

TODO: Make this configurable
*/}}
{{- define "smilecdr.readinessProbe" -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
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

{{/*
Define Smile CDR environment variables

Note:
This template simply collates the environment variables defined elsewhere to
provide a single entry point.
*/}}
{{- define "smilecdr.envVars" -}}
  {{- $envVars := list -}}
  {{- /* Include DB env vars */ -}}
  {{- $envVars = concat $envVars (include "smilecdr.dbEnvVars" . | fromYamlArray ) -}}
  {{- /* Include global extra env vars */ -}}
  {{- with .Values.extraEnvVars -}}
    {{- $envVars = concat $envVars . -}}
  {{- end -}}
  {{- /* Render the environments */ -}}
  {{- if ne (len $envVars) 0 -}}
    {{- printf "%v" (toYaml $envVars) -}}
  {{- end -}}
{{- end -}}

{{/*
Define all init containers

Note:
This template simply collates the init containers defined elsewhere to
provide a single entry point.
*/}}
{{- define "smilecdr.initContainers" -}}
  {{- $initContainers := list -}}
  {{- /* fail (printf "%v" (include "smilecdr.initFileContainers" . | fromYamlArray )) */ -}}
  {{- $initContainers = concat $initContainers (include "smilecdr.initFileContainers" . | fromYamlArray ) -}}
  {{- /* Uncomment once migration containers (i.e. Zero Outage Upgrades) are implemented */ -}}
  {{- /* $initContainers = append $initContainers (include "smilecdr.initMigrateContainers" . | fromYaml ) */ -}}
  {{- /* fail (printf "%v" ($initContainers)) */ -}}
  {{- if ne (len $initContainers) 0 -}}
    {{- printf "%v" (toYaml $initContainers) -}}
  {{- else -}}
    {{- printf "[]" -}}
  {{- end -}}
{{- end -}}
