{{/*
Define extra details for SmileCDR
*/}}
{{/*
Smile CDR Config Helpers
Creates config snippets.
*/}}
{{- define "smilecdr.modules.config" -}}
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
{{ printf "%s.config.%s \t= %s" $moduleKey $kConf (toYaml $vConf) -}}
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

  # Broker options are EMBEDDED_ACTIVEMQ, REMOTE_ACTIVEMQ, KAFKA, NONE

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
