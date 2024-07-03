{{/*
The following two templates, and the `scdr-image-pull-secret.yaml` are deprecated and will be removed at some point.
Passing in secret values directly via the chart is not recommended, so the functionality will be removed to prevent
bad habits forming.
*/}}

{{/*
Generate plaintext docker/config.json text
*/}}
{{- define "dockerconfigjson.plaintext" }}
  {{- if eq .type "values"}}
    {{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" (default "https://index.docker.io/v1/" .registry) (printf "%s:%s" .username .password | b64enc) }}
  {{- end }}
{{- end }}

{{/*
Generate base64 encoded docker/config.json from plain text
*/}}
{{- define "dockerconfigjson.encoded" }}
  {{- include "dockerconfigjson.plaintext" . | b64enc }}
{{- end }}
