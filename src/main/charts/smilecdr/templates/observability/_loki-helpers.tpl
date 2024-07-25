{{- define "observability.loki.config" -}}
  {{- $lokiConf := dict -}}
  {{- $saConfig := dict "create" false -}}
  {{- if .Values.observability.enabled -}}
    {{- /* if or (and ((.Values.observability.services).logging).enabled .Values.observability.services.logging.loki.enabled) (and ((.Values.observability.services).tracing).enabled (.Values.observability.services.tracing.loki).enabled) */ -}}

    {{- /* We define these for use elsewhere even if we do not install loki via the Helm Chart */ -}}
    {{- $_ := set $lokiConf "http_port" (default 3100 .Values.observability.services.logging.loki.httpPort) -}}
    {{- $_ := set $lokiConf "gprc_port" (default 9095 .Values.observability.services.logging.loki.gprcPort) -}}
    {{- $_ := set $lokiConf "host" (default "loki" .Values.observability.services.logging.loki.hostname) -}}
    {{- /* $_ := set $lokiConf "scheme" (default "http" .Values.observability.services.logging.loki.scheme) */ -}}
    {{- $_ := set $lokiConf "scheme" (ternary "https" "http" (default false .Values.observability.services.logging.loki.tls)) -}}
    {{- $_ := set $lokiConf "url" (printf "%s://%s:%s" $lokiConf.scheme $lokiConf.host $lokiConf.http_port) -}}

    {{- if and ((.Values.observability.services).logging).enabled .Values.observability.services.logging.loki.enabled .Values.observability.services.logging.loki.internal -}}
      {{- $_ := set $lokiConf "deployment" (dict "enabled" true) -}}

      {{- /* Set up the Service Account */ -}}
      {{- $_ := set $saConfig "name" (default (printf "%s-%s" (include "smilecdr.fullname" .) "loki" ) (.Values.observability.services.logging.loki.serviceAccount).name) -}}
      {{- /* if (.Values.observability.services.logging.loki.serviceAccount).name -}}
        {{- $_ := set $saConfig "name"  -}}
      {{- else -}}
        {{- $_ := set $saConfig "name"  -}}
      {{- end */ -}}
      {{- $_ := set $saConfig "create" (default true ((.Values.observability.services.logging.loki.serviceAccount).create )) -}}
      {{- /*if (.Values.observability.services.logging.loki.serviceAccount).create }}
        {{- $_ := set $saConfig "create" true -}}
      {{- else -}}
        {{- $_ := set $lokiConf "create" false -}}
      {{- end */ -}}
      {{- $_ := set $saConfig "annotations" (default dict (.Values.observability.services.logging.loki.serviceAccount).annotations) -}}
      
      {{- /* TODO: Add logic to only set up this if using S3. If not using S3, all logs will be lost on pod restart.
          Not going down the path of persistent volumes and stateful sets for this solution as it
          sets up a false sense of security for log durability. */ -}}
      {{- $_ := set $lokiConf "bucketNames" .Values.observability.services.logging.loki.bucketNames -}}
      {{- $_ := set $lokiConf "bucketRegion" (default "us-east-1" .Values.observability.services.logging.loki.bucketRegion) -}}

    {{- end -}}
  {{- end -}}
  {{- $_ := set $lokiConf "serviceAccount" $saConfig -}}
  {{- $lokiConf | toYaml -}}
{{- end -}}