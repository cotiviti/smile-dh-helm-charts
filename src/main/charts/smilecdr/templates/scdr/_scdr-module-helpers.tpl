{{/*
Extract and define details of module configurations for use elsewhere in the chart.
*/}}

{{/*
Define canonical dics/map of modules and configurations
Consume this elsewhere in the chart by unserializing it like so:
{{- $modules := include "smilecdr.modules" . | fromYaml -}}
*/}}
{{- define "smilecdr.modules" -}}
  {{/* Include all default modules unless usedefaultmodules is disabled */}}
  {{- $modules := dict -}}
  {{- if $.Values.modules.usedefaultmodules -}}
    {{- $modules = ( $.Files.Get "default-modules.yaml" | fromYaml ).modules -}}
  {{- end -}}
  {{- /* Include any user-defined module overrides, omitting the defaultmosules flag */ -}}
  {{- $_ := mergeOverwrite $modules ( omit $.Values.modules "usedefaultmodules" ) -}}
  {{/* Return as serialized Yaml */}}
  {{- $modules | toYaml -}}
{{- end -}}

{{/*
Generate the configuration options in text format for all the enabled modules
*/}}
{{- define "smilecdr.modules.config.text" -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- $moduleText := "" -}}
  {{- $separatorText := "################################################################################" -}}
  {{- /* Loop through all defined modules */ -}}
  {{- range $k, $v := $modules -}}
    {{- /* Only add module to config if it's enabled */ -}}
    {{- if $v.enabled -}}
      {{- $name := default $k $v.name -}}
      {{- $title := "" -}}

      {{- if ($v.service).enabled -}}
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
      Default: No prefix
      */ -}}
      {{- $envDBPrefix := "" -}}

      {{- /*
      If either CrunchyData or External DB has more than one DB then create prefix
      */ -}}
      {{- if or (and $.Values.database.crunchypgo.enabled (gt (len $.Values.database.crunchypgo.users) 1)) (and $.Values.database.external.enabled (gt (len $.Values.database.external.databases) 1)) -}}
        {{- $envDBPrefix = printf "%s_" ( upper $k ) -}}
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
        {{- $svcFullPath := (printf "%s%s" (default "/" $.Values.specs.rootPath) $v.config.context_path) -}}
        {{ if eq $kConf "context_path" }}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf $svcFullPath -}}
        {{ else if eq $kConf "base_url.fixed" }}
          {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $kConf $.Values.specs.hostname $svcFullPath -}}
        {{ else if eq $kConf "issuer.url" }}
          {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $kConf $.Values.specs.hostname $svcFullPath -}}
        {{- /* Process remaining config items */ -}}
        {{- else -}}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf $vConf -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $moduleText -}}
{{- end -}}

{{/*
Define enabled services, extracted from the module definitions
Outputs as Serialized Yaml. If you need to parse the output, include it like so:
{{- $modules := include "smilecdr.modules" . | fromYaml -}}
*/}}
{{- define "smilecdr.services" -}}
  {{- $services := dict -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- range $k, $v := $modules -}}
    {{- if (and $v.enabled (($v.service).enabled)) -}}
      {{/* Creating each module key, if enabled and if it has an enabled endpoint. */}}
      {{- $service := dict -}}
      {{- $_ := set $service "contextPath" $v.config.context_path -}}
      {{- $_ := set $service "fullPath" (printf "%s%s" (default "/" $.Values.specs.rootPath) $v.config.context_path) -}}
      {{- $_ := set $service "svcName" $v.service.svcName -}}
      {{- $_ := set $service "port" $v.config.port -}}
      {{- $_ := set $services $k $service -}}
    {{- end -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}
