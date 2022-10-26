{{/*
Define extra details for SmileCDR
*/}}
{{/*
Smile CDR Config Helpers
Creates config snippets.
*/}}
{{- define "smilecdr.modules.config" -}}
{{- $services := include "smilecdr.services" . | fromYaml -}}
{{- range $k, $v := .Values.modules -}}
{{- if $v.enabled -}}
{{- $name := default $k $v.name -}}
{{- $title := "" -}}
{{- if hasKey $services $k -}}
{{- $title = printf "# ENDPOINT: %s" $name -}}
{{- else -}}
{{- $title = printf "# %s" $name -}}
{{- end -}}
{{- $moduleKey := printf "module.%s" $k }}
################################################################################
{{ $title }}
################################################################################
{{/* Only add type key conditionally */}}
{{- if hasKey $v "type" }}
{{- printf "%s.type \t= %s" $moduleKey $v.type -}}
{{ end -}}
{{/* Dependencies */}}
{{- range $kReq, $vReq := $v.requires }}
{{ printf "%s.requires.%s \t= %s" $moduleKey $kReq $vReq -}}
{{ end -}}
{{/* Module Configuration */}}
{{- range $kConf, $vConf := $v.config }}
{{/* Process Special Cases */}}
{{- if eq $kConf "context_path" -}}
{{ printf "%s.config.%s \t= %s" $moduleKey $kConf (get $services $k).fullPath  -}}
{{ else if eq $kConf "base_url.fixed" -}}
{{ printf "%s.config.%s \t= https://%s%s" $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath  -}}
{{ else if eq $kConf "issuer.url" -}}
{{ printf "%s.config.%s \t= https://%s%s" $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath  -}}
{{/* Process remaining config items */}}
{{ else -}}
{{ printf "%s.config.%s \t= %s" $moduleKey $kConf (toYaml $vConf) -}}
{{ end -}}
{{ end -}}
{{/* Process config items from env vars */}}
{{- range $kConf, $vConf := $v.configFromEnv }}
{{ printf "%s.config.%s \t= #{env['%s']}" $moduleKey $kConf $vConf -}}
{{ end }}
{{ end -}}
{{- end -}}
{{- end -}}