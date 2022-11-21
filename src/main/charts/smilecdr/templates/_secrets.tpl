{{/*
Helper functions to help with secret handling

* Docker Config auth
  Can create a docker config auth file from credentials passed in via Helm values file
  Can use a docker config auth file (.docker/config.json)
  Can use externally provisioned K8s Secret

TODO: Support AWS Secrets & Configuration Provider
*/}}

{{/*
Create the name of the docker secrets to use
*/}}
{{- define "dockerconfigjson.secretName" -}}
{{- if eq .Values.image.credentials.type "secret" }}
{{- with index .Values.image.credentials.pullSecrets 0 -}}
{{- .name }}
{{- end -}}
{{- else }}
{{- "scdr-docker-pull-secrets" }}
{{- end }}
{{- end }}

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
  {{- else if eq .Values.image.credentials.type "jsonfile" }}
    {{- $.Files.Get .Values.image.credentials.jsonfile }}
  {{- end }}
{{- end }}

{{/*
Generate base64 encoded docker/config.json from plain text
*/}}
{{- define "dockerconfigjson.encoded" }}
  {{- include "dockerconfigjson.plaintext" . | b64enc }}
{{- end }}
