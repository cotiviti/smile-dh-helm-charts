{{/*
Define extra details for SmileCDR
*/}}
{{/*
Smile CDR Config Helpers
Creates config snippets.
*/}}
{{- define "smilecdr.modules.config" -}}
  {{- $modules := dict -}}
  {{- if $.Values.modules.usedefaultmodules -}}
    {{- $modules = ( $.Files.Get "default-modules.yaml" | fromYaml ).modules -}}
    {{- /* printf "defaults - %v\n\n" $modules */ -}}
  {{- end -}}
{{- $_ := mergeOverwrite $modules ( omit $.Values.modules "usedefaultmodules" ) -}}
{{- /* printf "\nbdc - %v\n\n" $.Values.modules */ -}}
{{- /* deepCopy ( omit $.Values.modules "usedefaultmodules" ) | merge $modules */ -}}
{{- /* printf "\nadc - %v\n\n" $.Values.modules */ -}}
{{- /* printf "omit - %v\n\n" ( omit $.Values.modules "usedefaultmodules" ) */ -}}
{{- /* printf "final - %v\n\n" $modules */ -}}
{{- $services := include "smilecdr.services" . | fromYaml -}}
{{- range $k, $v := $modules -}}
{{- if $v.enabled -}}
{{- $name := default $k $v.name -}}
{{- $title := "" -}}
{{- if hasKey $services $k -}}
{{- $title = printf "# ENDPOINT: %s" $name -}}
{{- else -}}
{{- $title = printf "# %s" $name -}}
{{- end -}}
{{- $moduleKey := printf "module.%s" $k -}}
################################################################################
{{ $title }}
################################################################################
{{- /* Only add type key conditionally */ -}}
{{- if hasKey $v "type" }}
{{ printf "%s.type \t= %s" $moduleKey $v.type -}}
{{- end -}}
{{- /* Dependencies */ -}}
{{ range $kReq, $vReq := $v.requires }}
{{ printf "%s.requires.%s \t= %s" $moduleKey $kReq $vReq -}}
{{- end -}}
{{- /* Module Configuration */ -}}
{{ range $kConf, $vConf := $v.config }}
{{- /* Process Special Cases */ -}}
{{ if eq $kConf "context_path" }}
{{ printf "%s.config.%s \t= %s" $moduleKey $kConf (get $services $k).fullPath  -}}
{{ else if eq $kConf "base_url.fixed" }}
{{ printf "%s.config.%s \t= https://%s%s" $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath  -}}
{{ else if eq $kConf "issuer.url" }}
{{ printf "%s.config.%s \t= https://%s%s" $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath  -}}
{{- /* Process remaining config items */ -}}
{{- else }}
{{ printf "%s.config.%s \t= %v" $moduleKey $kConf $vConf -}}
{{- end -}}
{{- end -}}
{{- /* Process config items from env vars */ -}}
{{- range $kConf, $vConf := $v.configFromEnv }}
{{ printf "%s.config.%s \t= #{env['%s']}" $moduleKey $kConf $vConf -}}
{{ end }}
{{ end }}
{{- end -}}
{{- end -}}

{{- define "smilecdr.cdrConfigDataHash" -}}
{{- if .Values.autoDeploy -}}
  {{- $data := ( include "smilecdr.cdrConfigData" .) -}}
  {{- printf "-%s" (sha256sum $data) -}}
{{- end -}}
{{- end -}}

{{- define "smilecdr.cdrConfigData" -}}
cdr-config-Master.properties: |-
  ################################################################################
  # Node Configuration
  ################################################################################
  node.id                                                        ={{ include "smilecdr.nodeId" . }}

{{ include "scdrcfg.messagebroker" . | indent 2 }}

  ################################################################################
  # Other Modules are Configured Below
  ################################################################################

  # The following setting controls where module configuration is ultimately stored.
  # When set to "DATABASE" (which is the default), the clustermgr configuration is
  # always read but the other modules are stored in the database upon the first
  # launch and their configuration is read from the database on subsequent
  # launches. When set to "PROPERTIES", values in this file are always used.
  #
  # In other words, in DATABASE mode, the module definitions below this line are
  # only used to seed the database upon the very first startup of the sytem, and
  # will be ignored after that. In PROPERTIES mode, the module definitions below
  # are read every time the system starts, and existing definitions and config are
  # overwritten by what is in this file.
  #
  node.propertysource                                            =PROPERTIES

{{ include "smilecdr.modules.config" . | indent 2 }}
{{- end -}}
