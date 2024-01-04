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
  {{- $ingresses := include "smilecdr.ingresses" . | fromYaml -}}
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

        {{- /* Canonically define the Kubernetes service resource name and service type */ -}}
        {{- $svcName := lower (printf "%s-scdrnode-%s-%s" $.Release.Name $cdrNodeValues.nodeId $theService.svcName) -}}
        {{- if $cdrNodeValues.oldResourceNaming -}}
          {{- $svcName = lower (printf "%s-scdr-svc-%s" $.Release.Name $theService.svcName) -}}
        {{- end -}}
        {{- $_ := set $theService "resourceName" $svcName -}}

        {{- /* Configure default ingress for modules with endpoints */ -}}

        {{- /* Determine if service is an endpoint */ -}}
        {{- $serviceHasEndpoint := false -}}
        {{- range $modulePrefix := $modulePrefixes -}}
          {{- if hasPrefix $modulePrefix $theModuleType -}}
            {{- $serviceHasEndpoint = true -}}
          {{- end -}}
        {{- end -}}

        {{- /* If we do not define the ingress, or if we do not set it to false,
            then set the service to use the default ingress */ -}}
        {{- /* If we do not define the ingress, or if we do not set it to false,
            then set the service to use the default ingress */ -}}
        {{- /* TODO: Make the condition logic more readable? */ -}}

        {{- if $serviceHasEndpoint -}}
          {{- /* Determine if the service has any ingress objects defined */ -}}
          {{- $ingressDefined := false -}}
          {{- $useDefaultIngress := true -}}
          {{- $forceDefaultIngress := false -}}
          {{- if hasKey $theService "ingresses" -}}
            {{- range $theIngressName, $theIngressSpec := $theService.ingresses -}}
              {{- /* Check to see if default ingress is explicitly enabled or disabled */ -}}
              {{- if eq $theIngressName "default" -}}
                {{- /* If the user has defined the default ingress... */ -}}
                {{- if $theIngressSpec.enabled -}}
                {{- /* ... Either forcefully enable it. */ -}}
                  {{- $forceDefaultIngress = true -}}
                {{- else -}}
                {{- /* ... Or disable it */ -}}
                  {{- $useDefaultIngress = false -}}
                {{- end -}}

              {{- /* This condition is only reached if we have other ingresses defined in the
                     service that ARE enabled. */ -}}
              {{- else if $theIngressSpec.enabled -}}
                {{- /* Check to make sure that the configured ingress has been defined */ -}}
                {{- if hasKey $ingresses $theIngressName -}}
                  {{- $ingressDefined = true -}}
                {{- else -}}
                  {{- fail (printf "Ingress `%s` configured in module `%s` has not been defined and cannot be used." $theIngressName $theModuleName ) -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}

          {{- if $ingressDefined -}}
            {{- /* Here we disable default ingress in the case that ingress is defined
                and the default ingress is not explicitly enabled */ -}}
            {{- $_ := set $theService "defaultIngress" $forceDefaultIngress -}}
          {{- else -}}
            {{- /* Here we enable default ingress unless it was explicitly disabled */ -}}
            {{- $_ := set $theService "defaultIngress" $useDefaultIngress -}}
          {{- end -}}
        {{- end -}}

        {{- /* Canonically define the Kubernetes service type, which depends on the ingress being used.
              This will use the first ingress found for this service. If multiple ingressses are defined
              they must use the same ingress type. */ -}}
        {{- $svcType := "ClusterIP" -}}
        {{- range $theIngressName, $theIngressSpec := $ingresses -}}
          {{- if or (eq "aws-lbc-alb" $theIngressSpec.type) (eq "azure-appgw" $theIngressSpec.type) -}}
            {{- $svcType = "NodePort" -}}
          {{- end -}}
        {{- end -}}
        {{- $_ := set $theService "serviceType" $svcType -}}

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
        {{- /* TODO: Clean this up to make it more readable. */ -}}
        {{- /* fullPath = /rootpath/context_path
               contextPath = /context_path
               normalized paths have no trailing slash  */ -}}
        {{- $fullPathElements := list -}}
        {{- if and (hasKey $cdrNodeValues.specs "rootPath") (ne $cdrNodeValues.specs.rootPath "/") -}}
          {{- $_ := set $theService "rootPath" (printf "/%s" (trimAll "/" $cdrNodeValues.specs.rootPath)) -}}
          {{- /* $fullPathElements = append $fullPathElements $theModuleSpec.rootPath */ -}}
          {{- $fullPathElements = append $fullPathElements $theService.rootPath -}}
        {{- else -}}
          {{- /* Add empty string so that join puts a '/' at the beginning. */ -}}
          {{- $fullPathElements = append $fullPathElements "" -}}
        {{- end -}}
        {{- /* Normalize `context_path` if it exists. */ -}}
        {{- if and (hasKey $theModuleSpec.config "context_path") (ne $theModuleSpec.config.context_path "") -}}
          {{- $_ := set $theModuleSpec.config "context_path" (trimAll "/" $theModuleSpec.config.context_path) -}}
          {{- $fullPathElements = append $fullPathElements $theModuleSpec.config.context_path -}}
        {{- end -}}
        {{- /* Create `full_path` based on `rootPath` and `context_path` */ -}}
        {{- if gt (len $fullPathElements) 1 -}}
          {{- $_ := set $theService "fullPath" (join "/" $fullPathElements) -}}
        {{- else if eq (first $fullPathElements) "" -}}
          {{- $_ := set $theService "fullPath" "/" -}}
        {{- end -}}

        {{- $annotations := dict -}}
        {{- range $theIngressName, $theIngressSpec := $ingresses -}}
          {{ if eq "azure-appgw" $theIngressSpec.type -}}
            {{- $path := join "/" (append $fullPathElements "endpoint-health") -}}
            {{- /* $path := printf "%sendpoint-health" (default "/" $theService.fullPath) */ -}}
            {{- /* $path := printf "%sendpoint-health" (default "/" $theModuleSpec.config.context_path) */ -}}
            {{- /* if $theService.contextPath -}}
              {{- $path = join "/" (append $fullPathElements $theService.contextPath "eendpoint-health") -}}
            {{- end */ -}}
            {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-path" $path -}}
          {{- end -}}
        {{- end -}}
        {{- $_ := set $theService "annotations" $annotations -}}

        {{- /* If this module has the Readiness Probe enabled, then
            enable it in the service */ -}}
        {{- if hasKey $theModuleSpec "enableReadinessProbe" -}}
          {{- $_ := set $theService "enableReadinessProbe" $theModuleSpec.enableReadinessProbe -}}
        {{- else -}}
          {{- $_ := set $theService "enableReadinessProbe" false -}}
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

    {{- $theService := dict -}}
    {{- if ($theModuleSpec.service).enabled -}}
        {{- $theService = $theModuleSpec.service -}}
    {{- end -}}
    {{- if $theService.enabled -}}
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
        {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $theConfigItemName $theService.fullPath -}}
      {{- else if eq $theConfigItemName "base_url.fixed" -}}
        {{- $baseUrl := "" -}}
        {{- if eq $theConfigItemValue "default" -}}
          {{- $baseUrl = printf "https://%s%s" $.Values.specs.hostname $theService.fullPath -}}
        {{- else if eq $theConfigItemValue "localhost" -}}
          {{- /* Use `localhost` when connecting from other components in the same pod, e.g. Fhir Gateway module */ -}}
          {{- $baseUrl = printf "http://localhost:%s%s" (toString $flattenedConf.port) $theService.fullPath -}}
        {{- else if eq $theConfigItemValue "service" -}}
          {{- /* Use K8s service object. e.g When connecting from other cluster-local components */ -}}
          {{- if $theService.enabled -}}
            {{- $baseUrl = printf "http://%s-scdr-svc-%s:%s%s" $.Release.Name ($theService.svcName | lower) (toString $flattenedConf.port) $theService.fullPath -}}
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
        {{- /* This is not a Smile CDR config so not using it. Only used to help with logic for `base_url.fixed` auto-configuration */ -}}
      {{- else if eq $theConfigItemName "issuer.url" -}}
        {{- /* If set to 'default', this will set the URL to 'https://hostname/servicename' where hostname is the main hostname for the
            deployment, and servicename is the context path for the module that this is being defined in.
            'default' is an invalid configuration in the context of a non-endpoint module.
            Any value other than 'default' is used as-is. */ -}}
        {{- if eq $theConfigItemValue "default" -}}
          {{- if $theService.fullPath -}}
            {{- $moduleText = printf "%s%s.config.%s \t= https://%s%s\n" $moduleText $moduleKey $theConfigItemName $.Values.specs.hostname $theService.fullPath -}}
          {{- else -}}
            {{- fail (printf "Module %s cannot use 'default' for `issuer.url` config item." $moduleKey) -}}
          {{- end -}}
        {{- else -}}
          {{- $moduleText = printf "%s%s.config.%s \t= %s\n" $moduleText $moduleKey $theConfigItemName $theConfigItemValue -}}
        {{- end -}}

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
    {{- $theService := dict -}}
    {{- if ($theModuleSpec.service).enabled -}}
      {{- $theService = $theModuleSpec.service -}}
      {{/* Creating each module key, if enabled and if it has an enabled endpoint. */}}
      {{- $service := dict -}}
      {{- $_ := set $service "contextPath" $theModuleSpec.config.context_path -}}
      {{- $_ := set $service "fullPath" $theService.fullPath -}}
      {{- $_ := set $service "healthcheckPath" (join "/" (list (trimSuffix "/" $theService.fullPath) (trimAll "/" (default "endpoint-health" ($theModuleSpec.config.endpoint_health).path)))) -}}
      {{- $_ := set $service "svcName" ($theService.svcName | lower) -}}
      {{- $_ := set $service "resourceName" ($theService.resourceName | lower) -}}
      {{- $_ := set $service "serviceType" ($theService.serviceType) -}}
      {{- $_ := set $service "enableReadinessProbe" ($theService.enableReadinessProbe ) -}}
      {{- if or (not (hasKey $theService "hostName")) (eq $theService.hostName "default") -}}
        {{- $_ := set $service "hostName" ($.Values.specs.hostname | lower) -}}
      {{- else -}}
        {{- $_ := set $service "hostName" ($theService.hostName | lower) -}}
      {{- end -}}
      {{- $_ := set $service "port" $theModuleSpec.config.port -}}
      {{- $_ := set $service "defaultIngress" $theService.defaultIngress -}}
      {{- $_ := set $service "ingresses" $theService.ingresses -}}
      {{- $_ := set $service "annotations" $theService.annotations -}}
      {{- $_ := set $services $theModuleName $service -}}
    {{- end -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}
