{{/*
The following two templates, and the `scdr-image-pull-secret.yaml` are deprecated and will be removed at some point.
Passing in secret values directly via the chart is not recommended, so the functionality will be removed to prevent
bad habits forming.
*/}}

{{/*
Generate plaintext docker/config.json text
*/}}
{{- define "dockerconfigjson.plaintext" }}
  {{- if eq .Values.image.credentials.type "values"}}
    {{- print "{\"auths\":{" }}
      {{- range $index, $item := .Values.image.credentials.values }}
        {{- if $index }}
        {{- print "," }}
        {{- end }}
        {{- printf "\"%s\":{\"auth\":\"%s\"}" (default "https://index.docker.io/v1/" $item.registry) (printf "%s:%s" $item.username $item.password | b64enc) }}
      {{- end }}
    {{- print "}}" }}
  {{- end }}
{{- end }}

{{/*
Generate base64 encoded docker/config.json from plain text
*/}}
{{- define "dockerconfigjson.encoded" }}
  {{- include "dockerconfigjson.plaintext" . | b64enc }}
{{- end }}
