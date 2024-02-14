{{/*
Lightweight helper function to define which logging components are configured
*/}}
{{ define "observability.logs.enablement" }}

  {{- $enablementDict := dict -}}
  {{- $observabilityValues := get .Values "observability" -}}
  {{- if and (hasKey $observabilityValues.instrumentation "loki") $observabilityValues.instrumentation.loki.enabled -}}
    {{- $_ := set $enablementDict "lokiExport" true  -}}
  {{- end -}}

  {{- /* Add more here maybe*/ -}}

  {{- $enablementDict | toYaml  -}}
{{- end -}}
