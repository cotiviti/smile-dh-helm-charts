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
Define canonical dict/map of enabled modules and configurations. This is a validated and sanitised
version of the modules defined above.
Consume this elsewhere in the chart by unserializing it like so:
{{- $modules := include "smilecdr.modules" . | fromYaml -}}
Currently, this is the canonical module source for the following template helpers:
* smilecdr.services
* smilecdr.modules.config.text
* smilecdr.readinessProbe
* chartWarnings
*/}}
{{- define "smilecdr.modules" -}}
  {{- $modules := include "smilecdr.modules.raw" . | fromYaml -}}
  {{- $modulePrefixes := (include "smilecdr.moduleprefixeswithendpoints" . | fromYamlArray) -}}
  {{- $cdrNodeValues := $.Values -}}
  {{- range $theModuleName, $theModuleSpec := $modules -}}
    {{- $theModuleIsClustermgr := ternary true false (eq $theModuleName "clustermgr") -}}
    {{- /*
        Required keys:
        * `enabled`
        * `type` */ -}}
    {{- if not (hasKey $theModuleSpec "enabled" ) -}}
      {{- fail (printf "Module %s does not have `enabled` key set" $theModuleName) -}}
    {{- end -}}
    {{- /* The `clustermgr` module is the only one that does not require the `type` key
        */ -}}
    {{- if and $theModuleSpec.enabled (not $theModuleIsClustermgr) (not (hasKey $theModuleSpec "type" )) -}}
      {{- fail (printf "Module %s does not have `type` key set" $theModuleName) -}}
    {{- end -}}

    {{- /* Only include the module if it's the clustermgr or if it's an explicitly enabled module */ -}}
    {{- if or $theModuleIsClustermgr $theModuleSpec.enabled -}}

      {{- $theModuleType := ternary nil $theModuleSpec.type $theModuleIsClustermgr -}}
      {{- $theModuleConfig := ($theModuleSpec.config) -}}

      {{- if ($theModuleSpec.service).enabled -}}
        {{- $theService := $theModuleSpec.service -}}

        {{- /* Configure default ingress for modules with endpoints */ -}}
        {{- $serviceHasEndpoint := false -}}
        {{- range $modulePrefix := $modulePrefixes -}}
          {{- if hasPrefix $modulePrefix $theModuleType -}}
            {{- $serviceHasEndpoint = true -}}
          {{- end -}}
        {{- end -}}

        {{- /* If we do not define the ingress, or if we do not set it to false,
            then set the service to use the default ingress */ -}}
        {{- /* TODO: Make the condition logic more readable? */ -}}
        {{- if and $serviceHasEndpoint (or (not (hasKey (($theService.ingresses).default) "enabled")) (ne $theService.ingresses.default.enabled false)) -}}
          {{- $_ := set $theService "defaultIngress" true -}}
        {{- else -}}
          {{- $_ := set $theService "defaultIngress" false -}}
        {{- end -}}

        {{- /* Set `base_url.fixed` for FHIR endpoint modules */ -}}
        {{- if or (hasPrefix "ENDPOINT_FHIR_" $theModuleType) (hasPrefix "ENDPOINT_HYBRID_PROVIDERS" $theModuleType) -}}
          {{- /* Only update if not manually set! */ -}}
          {{- if not (hasKey $theModuleSpec.config "base_url.fixed") -}}
            {{- if $theService.defaultIngress -}}
              {{- $_ := set $theModuleConfig "base_url.fixed" "default" -}}
            {{- else -}}
              {{- $_ := set $theModuleConfig "base_url.fixed" "service" -}}
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
            {{- if $theService.defaultIngress -}}
              {{- if ne (get $theModuleConfig "base_url.fixed") "default" -}}
                {{- if not (get $theModuleConfig "base_url.mismatch_allowed") -}}
                  {{- fail (printf "`base_url.fixed` is set to `%s` for the `%s` module. This will not work as ingress is enabled for this module." (get $theModuleConfig "base_url.fixed") $theModuleName ) -}}
                {{- end -}}
              {{- end -}}
            {{- else -}}
              {{- /* Ingress is disabled, but `base_url.fixed` is still set to default
                    We change it here to `service` in this case so that it's handled
                    correctly later on. */ -}}
              {{- if eq (get $theModuleConfig "base_url.fixed") "default" -}}
                {{- $_ := set $theModuleConfig "base_url.fixed" "service" -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}

        {{- /* Generate fullPath and normalize context_path */ -}}
        {{- $fullPathElements := list -}}
        {{- if and (hasKey $cdrNodeValues.specs "rootPath") (ne $cdrNodeValues.specs.rootPath "/") -}}
          {{- $_ := set $theModuleSpec.service "rootPath" (printf "/%s" (trimAll "/" $cdrNodeValues.specs.rootPath)) -}}
          {{- $fullPathElements = append $fullPathElements $theModuleSpec.rootPath -}}
        {{- else -}}
          {{- $fullPathElements = append $fullPathElements "" -}}
        {{- end -}}
        {{- /* Normalize `context_path` if it exists. */ -}}
        {{- if and (hasKey $theModuleSpec.config "context_path") (ne $theModuleSpec.config.context_path "") -}}
          {{- $_ := set $theModuleSpec.config "context_path" (trimAll "/" $theModuleSpec.config.context_path) -}}
          {{- $fullPathElements = append $fullPathElements $theModuleSpec.config.context_path -}}
        {{- end -}}
        {{- /* Create `full_path` based on `rootPath` and `context_path` */ -}}
        {{- if gt (len $fullPathElements) 1 -}}
          {{- $_ := set $theModuleSpec.service "fullPath" (join "/" $fullPathElements) -}}
        {{- else if eq (first $fullPathElements) "" -}}
          {{- $_ := set $theModuleSpec.service "fullPath" "/" -}}
        {{- end -}}

        {{- /* Canonically define the Kubernetes service resource name and service type */ -}}
        {{- $svcName := lower (printf "%s-scdrnode-%s-%s" $.Release.Name $cdrNodeValues.nodeId $theModuleSpec.service.svcName) -}}
        {{- if $cdrNodeValues.oldResourceNaming -}}
          {{- $svcName = lower (printf "%s-scdr-svc-%s" $.Release.Name $theModuleSpec.service.svcName) -}}
        {{- end -}}
        {{- $_ := set $theModuleSpec.service "resourceName" $svcName -}}

        {{- $svcType := "ClusterIP" -}}
        {{- if or (eq "aws-lbc-alb" $cdrNodeValues.ingress.type) (eq "azure-appgw" $cdrNodeValues.ingress.type) -}}
          {{- $svcType = "NodePort" -}}
        {{- end -}}
        {{- $_ := set $theModuleSpec.service "serviceType" $svcType -}}

        {{- /* If this module has the Readiness Probe enabled, then
            enable it in the service */ -}}
        {{- if hasKey $theModuleSpec "enableReadinessProbe" -}}
          {{- $_ := set $theModuleSpec.service "enableReadinessProbe" $theModuleSpec.enableReadinessProbe -}}
        {{- else -}}
          {{- $_ := set $theModuleSpec.service "enableReadinessProbe" false -}}
        {{- end -}}

      {{- end -}}
      {{- $deepConfig := include "sdhCommon.unFlattenDict" $theModuleConfig | fromYaml -}}
      {{- $_ := set $theModuleSpec "config" $deepConfig -}}
      {{- /* We don't need the enabled key any longer */ -}}
      {{- $_ := unset $theModuleSpec "enabled" -}}
    {{- else -}}
      {{- /* Remove module if it was disabled */ -}}
      {{- $_ := unset $modules $theModuleName -}}
    {{- end -}}
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
  {{- /* Appsphere module. Currently only APP_GALLERY  */ -}}
  {{- $modulesWithEndpoints = append $modulesWithEndpoints "APP_GALLERY" -}}
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
  {{- range $theModuleName, $theModuleSpec := $modules -}}
    {{- $name := default $theModuleName $theModuleSpec.name -}}
    {{- $title := "" -}}

    {{- if ($theModuleSpec.service).enabled -}}
      {{- $title = printf "ENDPOINT: %s" $name -}}
    {{- else -}}
      {{- $title = printf "%s" $name -}}
    {{- end -}}
    {{- $moduleKey := printf "module.%s" $theModuleName -}}
    {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
    {{- $moduleText = printf "%s# %s\n" $moduleText $title -}}
    {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}

    {{- /* Only add type key conditionally */ -}}
    {{- if hasKey $theModuleSpec "type" -}}
      {{- $moduleText = printf "%s%s.type \t= %s\n" $moduleText $moduleKey $theModuleSpec.type -}}
    {{- end -}}

    {{- /* Add dependencies */ -}}
    {{- range $theRequiresType, $theRequiresModuleName := $theModuleSpec.requires -}}
      {{- /* Sanity check to ensure dependency modules exist */ -}}
      {{- if has $theRequiresModuleName (keys $modules)  -}}
        {{- $moduleText = printf "%s%s.requires.%s \t= %s\n" $moduleText $moduleKey $theRequiresType $theRequiresModuleName -}}
      {{- else -}}
        {{- fail (printf "Module %s depends on module %s which does not exist, or has not been enabled!" $theModuleName $theRequiresModuleName) -}}
      {{- end -}}
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
      {{- $envDBPrefix = printf "%s_" ( upper $theModuleName ) -}}
    {{- end -}}

    {{- /* Get flattened configuration */ -}}
    {{- $flattenedConf := include "sdhCommon.flattenConf" $theModuleSpec.config | fromYaml -}}

    {{- /* Module Configuration */ -}}
    {{- range $theConfigItemName, $theConfigItemValue := $flattenedConf -}}
      {{- $theConfigItemValue = toString $theConfigItemValue -}}

      {{- /* TODO: Move all of these special use cases into config parsing template.
          */ -}}

      {{- /*
      If the value contains "DB_" then add the env prefix
      */ -}}
      {{- if contains "#{env['DB_" $theConfigItemValue -}}
        {{- $theConfigItemValue = replace "#{env['DB_" (printf "#{env['%sDB_" $envDBPrefix ) $theConfigItemValue -}}
      {{- end -}}

      {{- /* Process Special Cases */ -}}
      {{- if eq $theConfigItemName "context_path" -}}
        {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $theConfigItemName $theModuleSpec.service.fullPath -}}
      {{- else if eq $theConfigItemName "base_url.fixed" -}}
        {{- $baseUrl := "" -}}
        {{- if eq $theConfigItemValue "default" -}}
          {{- $baseUrl = printf "https://%s%s" $.Values.specs.hostname $theModuleSpec.service.fullPath -}}
        {{- else if eq $theConfigItemValue "localhost" -}}
          {{- /* Use `localhost` when connecting from other components in the same pod, e.g. Fhir Gateway module */ -}}
          {{- $baseUrl = printf "http://localhost:%s%s" (toString $flattenedConf.port) $theModuleSpec.service.fullPath -}}
        {{- else if eq $theConfigItemValue "service" -}}
          {{- /* Use K8s service object. e.g When connecting from other cluster-local components */ -}}
          {{- if ($theModuleSpec.service).enabled -}}
            {{- $baseUrl = printf "http://%s-scdr-svc-%s:%s%s" $.Release.Name ($theModuleSpec.service.svcName | lower) (toString $flattenedConf.port) $theModuleSpec.service.fullPath -}}
          {{- else -}}
            {{- fail (printf "Module %s cannot reference service for `base_url.fixed`` as there is no enabled service for this module" $moduleKey ) -}}
          {{- end -}}
        {{- else -}}
          {{- /* If the full `base_url` is provided and does not match the port and context root, then
                  referred links and the `Location` header will be incorrect. */ -}}
          {{- $baseUrl = $theConfigItemValue -}}
        {{- end -}}
        {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $theConfigItemName $baseUrl -}}
      {{- else if eq $theConfigItemName "base_url.mismatch_allowed" -}}
        {{- /* This is not a smile config so not using it. Only used to help with logic for `base_url.fixed` auto-configuration */ -}}
      {{- else if eq $theConfigItemName "issuer.url" -}}
        {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $theConfigItemName $.Values.specs.hostname $theModuleSpec.service.fullPath -}}
      {{- /* Process remaining config items */ -}}
      {{- else -}}
        {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $theConfigItemName $theConfigItemValue -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $moduleText -}}
{{- end -}}

{{/*
Define enabled services, extracted from the module definitions
Outputs as Serialized Yaml. If you need to parse the output, include it like so:
{{- $modules := include "smilecdr.services" . | fromYaml -}}
*/}}
{{- define "smilecdr.services" -}}
  {{- $services := dict -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- range $theModuleName, $theModuleSpec := $modules -}}
    {{- if ($theModuleSpec.service).enabled -}}
      {{/* Creating each module key, if enabled and if it has an enabled endpoint. */}}
      {{- $service := dict -}}
      {{- $_ := set $service "contextPath" $theModuleSpec.config.context_path -}}
      {{- $_ := set $service "fullPath" $theModuleSpec.service.fullPath -}}
      {{- $_ := set $service "svcName" ($theModuleSpec.service.svcName | lower) -}}
      {{- $_ := set $service "resourceName" ($theModuleSpec.service.resourceName | lower) -}}
      {{- $_ := set $service "serviceType" ($theModuleSpec.service.serviceType) -}}
      {{- $_ := set $service "enableReadinessProbe" ($theModuleSpec.service.enableReadinessProbe ) -}}
      {{- if or (not (hasKey $theModuleSpec.service "hostName")) (eq $theModuleSpec.service.hostName "default") -}}
        {{- $_ := set $service "hostName" ($.Values.specs.hostname | lower) -}}
      {{- else -}}
        {{- $_ := set $service "hostName" ($theModuleSpec.service.hostName | lower) -}}
      {{- end -}}
      {{- $_ := set $service "port" $theModuleSpec.config.port -}}
      {{- $_ := set $service "defaultIngress" $theModuleSpec.service.defaultIngress -}}
      {{- $_ := set $services $theModuleName $service -}}
    {{- end -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}
