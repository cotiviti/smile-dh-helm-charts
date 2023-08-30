{{/*
Define environment variables depending on which component
being created.
*/}}

{{/*
Words
We will detect which component it is and then define env vars based on that
Individual env vars can be added or overriden in `.Values.components.<component>.envVars` (List of env maps)
*/}}
{{- define "component.envVars" -}}
  {{- $envVars := list -}}

  {{- /* Enable ingress related vars for all components.
      Some do not use these vars, but may do in the future
      so adding them now for all */ -}}
  {{- /* This uses the FIRST `path` from the first ingress `host` as a default.
      Can override with `component.ingress.defaultHost` and `defaultPath` */ -}}
  {{- if .Values.ingress.enabled -}}
    {{- $defaultHostMap := first .Values.ingress.hosts -}}
    {{- $defaultHost := default $defaultHostMap.host .Values.ingress.defaultHost -}}
    {{- $defaultPath := ternary (printf "/%s/" .Values.name) (first $defaultHostMap.paths).path (empty $defaultHostMap.paths) -}}
    {{- $appPath := ternary $defaultPath (printf "%s" .Values.ingress.defaultPath) (empty .Values.ingress.defaultPath) -}}

    {{- $publicURL := printf "%s://%s" "https" $defaultHost -}}
    {{- $envVars = append $envVars (dict "name" "PUBLIC_URL" "value" $publicURL) -}}
    {{- $envVars = append $envVars (dict "name" "CONTEXT_ROOT" "value" (default $appPath .Values.ingress.path)) -}}
    {{- $envVars = append $envVars (dict "name" "LISTEN_PORT" "value" (toString (default 8080 .Values.service.port))) -}}
  {{- end -}}

  {{- /* Special environment variables for PMP Services and PMP User Services */ -}}
  {{- if eq (lower .Values.componentType) "services" -}}
    {{- /* Match the fhir endpoint service name in the smile cdr chart, based on release name */ -}}
    {{- $fhirClusterEndpoint := printf "http://%s-scdr-svc-fhir:8000/fhir_request" .Release.Name -}}
    {{- $fhirClusterEndpoint = ternary $fhirClusterEndpoint .Values.fhirClusterEndpointOverride (empty .Values.fhirClusterEndpointOverride) -}}
    {{- $envVars = append $envVars (dict "name" "resourceProviderURI" "value" $fhirClusterEndpoint) -}}

  {{- else if eq (lower .Values.componentType) "userservices" -}}
    {{- /* Default Environment variables for PMP User Services component */ -}}
    {{- /* Required Env Vars */ -}}
    {{- $envVars = append $envVars (dict "name" "authJwksUrl" "value" (required "You must provide `components.pmpUserServices.oidc.authJwksUrl`" .Values.oidc.authJwksUrl)) -}}
    {{- $envVars = append $envVars (dict "name" "authAuthority" "value" (required "You must provide `components.pmpUserServices.oidc.authAuthority`" .Values.oidc.authAuthority)) -}}
    {{- $envVars = append $envVars (dict "name" "authClientId" "value" (required "You must provide `components.pmpUserServices.oidc.authClientId`" .Values.oidc.authClientId)) -}}
    {{- $envVars = append $envVars (dict "name" "awsCognitoUserPoolId" "value" (required "Must provide `components.pmpUserServices.oidc.awsCognitoUserPoolId`" .Values.oidc.awsCognitoUserPoolId)) -}}
  {{- end -}}

  {{- /* Include extra secrets env vars */ -}}
  {{- $envVars = concat $envVars (include "sdhCommon.extraSecretsEnvVars" . | fromYamlArray ) -}}

  {{- range $k, $v := .Values.envVars -}}
    {{- $envVars = append $envVars (dict "name" $k "value" (toString $v)) -}}
  {{- end -}}
  {{- $envVars = concat $envVars .Values.extraEnvVars -}}
  {{- if gt (len $envVars) 0 -}}
  {{- printf "%s" ($envVars | toYaml) -}}
  {{- else -}}
  {{- list -}}
  {{- end -}}
{{- end -}}
