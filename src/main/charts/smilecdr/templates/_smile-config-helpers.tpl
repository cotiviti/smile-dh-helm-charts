{{/*
Define extra details for SmileCDR
*/}}
{{/*
Smile CDR Config Helpers
Creates config snippets.
*/}}
{{- define "smilecdr.modules.config" -}}
  {{- $moduleText := "" -}}
  {{- $separatorText := "################################################################################" -}}
  {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
  {{- $moduleText = printf "%s# Node Configuration\n" $moduleText -}}
  {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
  {{- $moduleText = printf "%snode.id \t= %s\n\n" $moduleText (include "smilecdr.nodeId" .) -}}
  {{- $moduleText = printf "%s%s\n\n" $moduleText (include "scdrcfg.messagebroker" .) -}}
  {{- $moduleText = printf "%s%s\n" $moduleText (include "smilecdr.cdrConfigTextBlob" .) -}}
  {{- $moduleText = printf "%snode.propertysource \t= %s\n" $moduleText "PROPERTIES" -}}

  {{- $modules := dict -}}
  {{- if $.Values.modules.usedefaultmodules -}}
    {{- $modules = ( $.Files.Get "default-modules.yaml" | fromYaml ).modules -}}
  {{- end -}}
  {{- $_ := mergeOverwrite $modules ( omit $.Values.modules "usedefaultmodules" ) -}}
  {{- $services := include "smilecdr.services" . | fromYaml -}}
  {{- range $k, $v := $modules -}}

    {{- /* Only add module to config if it's enabled */ -}}
    {{- if $v.enabled -}}
      {{- $name := default $k $v.name -}}
      {{- $title := "" -}}
      {{- if hasKey $services $k -}}
        {{- $title = printf "ENDPOINT: %s" $name -}}
      {{- else -}}
        {{- $title = printf "%s" $name -}}
      {{- end -}}
      {{- $moduleKey := printf "module.%s" $k -}}
      {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
      {{- $moduleText = printf "%s# %s\n" $moduleText $title -}}
      {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}

      {{- /* Only add type key conditionally */ -}}
      {{- if hasKey $v "type" -}}
        {{- $moduleText = printf "%s%s.type \t= %s\n" $moduleText $moduleKey $v.type -}}
      {{- end -}}

      {{- /* Add dependencies */ -}}
      {{- range $kReq, $vReq := $v.requires -}}
        {{- $moduleText = printf "%s%s.requires.%s \t= %s\n" $moduleText $moduleKey $kReq $vReq -}}
      {{- end -}}

      {{- /*
      Defining environment prefix for values with `DB_`. This is
      so that we can define multiple databases.
      */ -}}
      {{- $envDBPrefix := printf "%s_" ( upper $k ) -}}
      {{- /*
      If there is only a single DB, don't use a prefix as the same
      environment variables will be shared amongst all modules.
      The if logic can be hard to follow here:
      If (using crunchy and users < 1) OR (using external and users < 1)
      Then no prefix
      */ -}}
      {{- if or (and $.Values.database.crunchypgo.enabled (le (len $.Values.database.crunchypgo.users) 1)) (and $.Values.database.external.enabled (le (len $.Values.database.external.databases) 1)) -}}
        {{- $envDBPrefix = "" -}}
      {{- end -}}

      {{- /* Module Configuration */ -}}
      {{ range $kConf, $vConf := $v.config }}
        {{- $vConf = toString $vConf -}}

        {{- /*
        If the value contains "DB_" then add the env prefix
        */ -}}
        {{- if contains "#{env['DB_" $vConf -}}
          {{- $vConf = replace "#{env['DB_" (printf "#{env['%sDB_" $envDBPrefix ) $vConf -}}
        {{- end -}}

        {{- /* Process Special Cases */ -}}
        {{ if eq $kConf "context_path" }}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf (get $services $k).fullPath -}}
        {{ else if eq $kConf "base_url.fixed" }}
          {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath -}}
        {{ else if eq $kConf "issuer.url" }}
          {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $kConf $.Values.specs.hostname (get $services $k).fullPath -}}
        {{- /* Process remaining config items */ -}}
        {{- else -}}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf $vConf -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s\n" $moduleText -}}
{{- end -}}

{{- define "smilecdr.cdrConfigTextBlob" -}}
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
{{- end -}}

{{- define "smilecdr.cdrConfigDataHash" -}}
{{- if .Values.autoDeploy -}}
  {{- $data := ( include "smilecdr.cdrConfigData" .) -}}
  {{- printf "-%s" (sha256sum $data) -}}
{{- end -}}
{{- end -}}

{{- define "smilecdr.cdrConfigData" -}}
cdr-config-Master.properties: |-
{{ include "smilecdr.modules.config" . | indent 2 }}
{{- end -}}
