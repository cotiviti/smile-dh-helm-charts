{{/*
Extract and define details of module configurations for use elsewhere in the chart.
*/}}

{{/*
Define raw dict/map of modules and configurations
This represents the modules configuration as passed in to the Helm Chart and does
not do any validation or sanitation of the configuration.
*/}}
{{- define "smilecdr.modules.raw" -}}
  {{/* Include all default modules unless useDefaultModules is disabled */}}
  {{- $modules := dict -}}
  {{- if $.Values.modules.useDefaultModules -}}
    {{- $modules = ( $.Files.Get "default-modules.yaml" | fromYaml ).modules -}}
  {{- end -}}
  {{- /* Include any user-defined module overrides, omitting the useDefaultModules flag */ -}}
  {{- $_ := mergeOverwrite $modules ( omit $.Values.modules "useDefaultModules" ) -}}
  {{/* Return as serialized Yaml */}}
  {{- $modules | toYaml -}}
{{- end -}}

{{/*
Define canonical dict/map of modules and configurations. This is a validated and sanitised
version of the modules defined above.
Consume this elsewhere in the chart by unserializing it like so:
{{- $modules := include "smilecdr.modules" . | fromYaml -}}
*/}}
{{- define "smilecdr.modules" -}}
  {{- $modules := include "smilecdr.modules.raw" . | fromYaml -}}
  {{- $modulePrefixes := (include "smilecdr.moduleprefixeswithendpoints" . | fromYamlArray) -}}
  {{- range $k, $v := $modules -}}
    {{- if ($v.service).enabled -}}
      {{- $service := $v.service -}}

      {{- /* Configure default ingress for modules with endpoints */ -}}
      {{- $serviceHasEndpoint := false -}}
      {{- range $modulePrefix := $modulePrefixes -}}
        {{- if hasPrefix $modulePrefix $v.type -}}
          {{- $serviceHasEndpoint = true -}}
        {{- end -}}
      {{- end -}}

      {{- /* If we do not define the ingress, or if we do not set it to false, then enable default ingress */ -}}
      {{- if and $serviceHasEndpoint (or (not (hasKey (($v.service.ingresses).default) "enabled")) (ne $v.service.ingresses.default.enabled false)) -}}
        {{- $_ := set $service "defaultIngress" true -}}
      {{- else -}}
        {{- $_ := set $service "defaultIngress" false -}}
      {{- end -}}

      {{- /* TODO: Un-flatten module configurations. The internal representation of the module configuration
          is hierarchical, so
          `config.item.name: value`
          should become:
          ```
          config:
             item:
               name: value
          ```
          This makes the internal representation more consistent.
          */ -}}
      {{- /* Insert code here */ -}}

      {{- /* Set `base_url.fixed` for FHIR endpoint modules */ -}}
      {{- if or (hasPrefix "ENDPOINT_FHIR_" $v.type) (hasPrefix "ENDPOINT_HYBRID_PROVIDERS" $v.type) -}}
        {{- /* Only update if not manually set! */ -}}
        {{- if not (hasKey $v.config "base_url.fixed") -}}
          {{- if $v.service.defaultIngress -}}
            {{- $_ := set $v.config "base_url.fixed" "default" -}}
          {{- else -}}
            {{- $_ := set $v.config "base_url.fixed" "service" -}}
          {{- end -}}
        {{- else -}}
          {{- /* If `base_url.fixed` is defined but does not match the ingress
                options, then throw an error. Ideally `base_url.fixed` should
                not be explicitly defined as this is autoconfigured based on
                ingress settings. If the user really must override this, then
                they must enable using `base_url.mismatch_allowed: true`. This
                is not supported and may lead to unpredictable behaviour. It
                is only suitable for troubleshooting where you need to override
                the value. */ -}}
          {{- if $v.service.defaultIngress -}}
            {{- if ne (get $v.config "base_url.fixed") "default" -}}
              {{- if not (get $v.config "base_url.mismatch_allowed") -}}
                {{- fail (printf "`base_url.fixed` is set to `%s` for the `%s` module. This will not work as ingress is enabled for this module." (get $v.config "base_url.fixed") $k ) -}}
              {{- end -}}
            {{- end -}}
          {{- else -}}
            {{- /* Ingress is disabled, but `base_url.fixed` is still set to default
                   We change it here to `service` in this case so that it's handled
                   correctly later on. */ -}}
            {{- if eq (get $v.config "base_url.fixed") "default" -}}
              {{- $_ := set $v.config "base_url.fixed" "service" -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $deepConfig := include "sdhCommon.unFlattenDict" $v.config | fromYaml -}}
    {{- $_ := set $v "config" $deepConfig -}}
  {{- end -}}
  {{- $modules | toYaml -}}
{{- end -}}

{{/*
Define modules that expose HTTP listeners
This will ultimately be refactored into a full validation function
that will use the appropriate module prototypes
*/}}
{{- define "smilecdr.moduleprefixeswithendpoints" -}}
  {{- $modulesWithEndpoints := list -}}
  {{- /* We will accept module prefixes to make this a whole less verbose */ -}}
  {{- /* All workload endpoint modules, eg, FHIR_REST and FHIRWEB  */ -}}
  {{- $modulesWithEndpoints = append $modulesWithEndpoints "ENDPOINT_" -}}
  {{- /* Any admin endpoints. Currently only ADMIN_JSON and ADMIN_WEB  */ -}}
  {{- $modulesWithEndpoints = append $modulesWithEndpoints "ADMIN_" -}}
  {{- /* Outbound security modules. Currently only SECURITY_OUT_SMART  */ -}}
  {{- $modulesWithEndpoints = append $modulesWithEndpoints "SECURITY_OUT_" -}}
  {{- $modulesWithEndpoints | toYaml -}}
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

      {{- /* Get flattened configuration */ -}}
      {{- $flattenedConf := include "sdhCommon.flattenConf" $v.config | fromYaml -}}

      {{- /* Module Configuration */ -}}
      {{- range $kConf, $vConf := $flattenedConf -}}
        {{- $vConf = toString $vConf -}}

        {{- /* TODO: Move all of these special use cases into separate module.
            */ -}}

        {{- /*
        If the value contains "DB_" then add the env prefix
        */ -}}
        {{- if contains "#{env['DB_" $vConf -}}
          {{- $vConf = replace "#{env['DB_" (printf "#{env['%sDB_" $envDBPrefix ) $vConf -}}
        {{- end -}}

        {{- /* Process Special Cases */ -}}
        {{- $svcFullPath := (printf "%s%s" (default "/" $.Values.specs.rootPath) $flattenedConf.context_path) -}}
        {{- if eq $kConf "context_path" -}}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf $svcFullPath -}}
        {{- else if eq $kConf "base_url.fixed" -}}
          {{- $baseUrl := "" -}}
          {{- if eq $vConf "default" -}}
            {{- $baseUrl = printf "https://%s%s" $.Values.specs.hostname $svcFullPath -}}
          {{- else if eq $vConf "localhost" -}}
            {{- /* Use `localhost` when connecting from other components in the same pod, e.g. Fhir Gateway module */ -}}
            {{- $baseUrl = printf "http://localhost:%s%s" (toString $flattenedConf.port) $svcFullPath -}}
          {{- else if eq $vConf "service" -}}
            {{- /* Use K8s service object. e.g When connecting from other cluster-local components */ -}}
            {{- if ($v.service).enabled -}}
              {{- $baseUrl = printf "http://%s-scdr-svc-%s:%s%s" $.Release.Name ($v.service.svcName | lower) (toString $flattenedConf.port) $svcFullPath -}}
            {{- else -}}
              {{- fail (printf "Module %s cannot reference service for `base_url.fixed`` as there is no enabled service for this module" $moduleKey ) -}}
            {{- end -}}
          {{- else -}}
            {{- /* If the full `base_url` is provided and does not match the port and context root, then
                   referred links and the `Location` header will be incorrect. */ -}}
            {{- $baseUrl = $vConf -}}
          {{- end -}}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $kConf $baseUrl -}}
        {{- else if eq $kConf "base_url.mismatch_allowed" -}}
          {{- /* This is not a smile config so not using it. Only used to help with logic for `base_url.fixed` auto-configuration */ -}}
        {{- else if eq $kConf "issuer.url" -}}
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
      {{- $_ := set $service "fullPath" (printf "%s%s" (default "/" $.Values.specs.rootPath) (default "" $v.config.context_path)) -}}
      {{- $_ := set $service "svcName" ($v.service.svcName | lower) -}}
      {{- if or (not (hasKey $v.service "hostName")) (eq $v.service.hostName "default") -}}
        {{- $_ := set $service "hostName" ($.Values.specs.hostname | lower) -}}
      {{- else -}}
        {{- $_ := set $service "hostName" ($v.service.hostName | lower) -}}
      {{- end -}}
      {{- $_ := set $service "port" $v.config.port -}}
      {{- $_ := set $service "defaultIngress" $v.service.defaultIngress -}}
      {{- $_ := set $services $k $service -}}
    {{- end -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}
