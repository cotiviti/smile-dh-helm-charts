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
Consume this elsewhere in the chart like so:
{{- $modules := include "smilecdr.modules" . | fromYaml -}}
Currently, this is the canonical module source for the following template helpers:
* smilecdr.services
* smilecdr.modules.config.text
* smilecdr.readinessProbe
* chartWarnings
*/}}
{{- define "smilecdr.modules" -}}
  {{- $modules := include "smilecdr.modules.raw" . | fromYaml -}}
  {{- $endpointModulePrefixes := (include "smilecdr.endpointModulePrefixes" . | fromYamlArray) -}}
  {{- $cdrNodeValues := $.Values -}}
  {{- $tlsConfig := $cdrNodeValues.tls -}}
  {{- $ingresses := include "smilecdr.ingresses" . | fromYaml -}}
  {{- $extDBConnections := (include "smilecdr.database.external.connections" $) | fromYamlArray -}}
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
        {{- /* TODO: Should this be moved to "smilecdr.services.enabledServices"? */ -}}
        {{- $svcName := lower (printf "%s-scdrnode-%s-%s" $.Release.Name $cdrNodeValues.cdrNodeId $theService.svcName) -}}
        {{- if $cdrNodeValues.oldResourceNaming -}}
          {{- $svcName = lower (printf "%s-scdr-svc-%s" $.Release.Name $theService.svcName) -}}
        {{- end -}}
        {{- $_ := set $theService "resourceName" $svcName -}}

        {{- /* Configure default ingress for modules with endpoints */ -}}

        {{- /* Determine if service is an endpoint */ -}}
        {{- $serviceHasEndpoint := false -}}
        {{- range $modulePrefix := $endpointModulePrefixes -}}
          {{- if hasPrefix $modulePrefix $theModuleType -}}
            {{- $serviceHasEndpoint = true -}}
          {{- end -}}
        {{- end -}}

        {{- /* If we do not define the ingress, or if we do not set it to false,
            then set the service to use the default ingress */ -}}
        {{- /* TODO: Make the condition logic more readable? */ -}}

        {{- /* The handling of the default ingress is pretty ugly.
               Needs a refactor. */ -}}

        {{- if $serviceHasEndpoint -}}
          {{- /* Determine if the service has any ingress objects defined */ -}}
          {{- $ingressDefined := false -}}
          {{- $useDefaultIngress := true -}}
          {{- $forceDefaultIngress := false -}}
          {{- /* Create list of enabled ingresses */ -}}
          {{- $enabledIngressNames := list -}}
          {{- $enabledIngressTypes := list -}}

          {{- if hasKey $theService "ingresses" -}}
            {{- range $theIngressName, $theIngressSpec := $theService.ingresses -}}
              {{- /* Check to see if default ingress is explicitly enabled or disabled */ -}}
              {{- if eq $theIngressName "default" -}}
                {{- /* If the user has defined the default ingress... */ -}}
                {{- if $theIngressSpec.enabled -}}
                {{- /* ... Either forcefully enable it. */ -}}
                  {{- $forceDefaultIngress = true -}}
                  {{- $enabledIngressNames = append $enabledIngressNames "default" -}}
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
                  {{- $enabledIngressNames = append $enabledIngressNames $theIngressName -}}
                {{- else -}}
                  {{- fail (printf "Ingress `%s` configured in module `%s` has not been defined and cannot be used." $theIngressName $theModuleName ) -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}
          {{- else -}}
            {{- /* `ingresses` not defined, so we will use the default one */ -}}
            {{- $enabledIngressNames = append $enabledIngressNames "default" -}}
          {{- end -}}

          {{- range $theIngressName, $theIngressSpec := $ingresses -}}
            {{- if has $theIngressName $enabledIngressNames -}}
              {{- $enabledIngressTypes = uniq (append $enabledIngressTypes (lower $theIngressSpec.type)) -}}
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
          {{- $_ := set $theService "enabledIngressNames" $enabledIngressNames -}}

          {{- /* Canonically define the Kubernetes service type, which depends on the ingress being used.
                This will use the first ingress found for this service. If multiple ingressses are defined
                they must use the same ingress type. */ -}}
          {{- $svcType := "ClusterIP" -}}
          {{ if or (has "aws-lbc-alb" $enabledIngressTypes) (has "azure-agic" $enabledIngressTypes) (has "azure-appgw" $enabledIngressTypes) -}}
            {{- $svcType = "NodePort" -}}
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
          {{- /* Create `fullPath` based on `rootPath` and `context_path` */ -}}
          {{- if gt (len $fullPathElements) 1 -}}
            {{- $_ := set $theService "fullPath" (join "/" $fullPathElements) -}}
          {{- else if eq (first $fullPathElements) "" -}}
            {{- $_ := set $theService "fullPath" "/" -}}
          {{- end -}}
          {{- $healthcheckPath := join "/" (list (trimSuffix "/" $theService.fullPath) (trimAll "/" (default "endpoint-health" (get $theModuleSpec.config "endpoint_health.path")))) -}}

          {{- /* Determine allowed HTTP response codes allowed for health checks. */ -}}
          {{- $allowedHealthcheckResponses := "" -}}
          {{- if hasKey $theService "allowedHealthcheckResponses" -}}
            {{- $allowedHealthcheckResponses = join "," $theService.allowedHealthcheckResponses -}}
          {{- end -}}
          {{- if not (contains "200" $allowedHealthcheckResponses) -}}
            {{- $allowedHealthcheckResponses = join "," (compact (prepend (splitList "," $allowedHealthcheckResponses) "200")) -}}
          {{- end -}}

          {{- /* TODO: Determine health probe tuning parameters.
                 Make them the same as the Readiness Probe tuning parameters??? */ -}}

          {{- /* Set service annotations. Typically used by Ingress controllers such as AWS Load Balancer Controller or Azure AGIC */ -}}
          {{- $annotations := dict -}}
          {{ if has "aws-lbc-alb" $enabledIngressTypes -}}
            {{- $_ := set $annotations "alb.ingress.kubernetes.io/healthcheck-path" $healthcheckPath -}}
            {{- $_ := set $annotations "alb.ingress.kubernetes.io/success-codes" $allowedHealthcheckResponses -}}
            {{- /* TODO: Add AWS ALB health probe tuning parameters */ -}}
          {{- else if or (has "azure-agic" $enabledIngressTypes) (has "azure-appgw" $enabledIngressTypes) -}}
            {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-path" $healthcheckPath -}}
            {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-status-codes" $allowedHealthcheckResponses -}}
            {{- /* TODO: Add Azure LB/AGIC health probe tuning parameters */ -}}
          {{- end -}}

          {{- /* Either set the new annotations if there are none, or merge with any existing ones */ -}}
          {{- if not (hasKey $theService "annotations") -}}
            {{- $_ := set $theService "annotations" $annotations -}}
          {{- else -}}
            {{- $_ := set $theService "annotations" (merge $annotations $theService.annotations)  -}}
          {{- end -}}

          {{- /* If this module has the Readiness Probe enabled, then
              enable it in the service */ -}}
          {{- if hasKey $theModuleSpec "enableReadinessProbe" -}}
            {{- $_ := set $theService "enableReadinessProbe" $theModuleSpec.enableReadinessProbe -}}
          {{- else -}}
            {{- $_ := set $theService "enableReadinessProbe" false -}}
          {{- end -}}

          {{- /* Determine TLS certificate configuration for the modules service */ -}}
          {{- /* This can be enabled in 2 places:
                  1. tls.defaultEndpointConfig
                  2. modules.modulename.service(Takes priority)
                */ -}}
          {{- $tlsSpec := dict "enabled" false -}}
          {{- $moduleExtraConfig := dict -}}
          {{- $defaultTlsCertificate := "default" -}}
          {{- if $tlsConfig.defaultEndpointConfig.enabled -}}
            {{- $defaultTlsCertificate = default "default" $tlsConfig.defaultEndpointConfig.tlsCertificate -}}
            {{- if and (hasKey $theService "tlsEnabled") (not $theService.tlsEnabled) -}}
              {{- /* Default is enabled, but this service has TLS explicitly disabled. Do nothing. */ -}}
            {{- else -}}
              {{- $_ := set $tlsSpec "enabled" true -}}
              {{- $_ := set $tlsSpec "tlsCertificate" (default $defaultTlsCertificate $theService.tlsCertificate) -}}
            {{- end -}}
            {{- if hasKey  $tlsConfig.defaultEndpointConfig "extraCdrConfig" -}}
              {{- $moduleExtraConfig = $tlsConfig.defaultEndpointConfig.extraCdrConfig -}}
            {{- end -}}
          {{- else -}}
            {{- /* defaultEndpointConfig is disabled. Allow explicit enablement in the service */ -}}
            {{- if $theService.tlsEnabled -}}
              {{- $_ := set $tlsSpec "enabled" true -}}
              {{- $_ := set $tlsSpec "tlsCertificate" (default $defaultTlsCertificate $theService.tlsCertificate) -}}
            {{- end -}}
          {{- end -}}
          {{- $_ := set $theService "tls" $tlsSpec -}}

          {{- /* Smile CDR module TLS Configuration */ -}}
          {{- if $theService.tls.enabled -}}
            {{- /* If the "smilecdr.modules" helper gets called 'directly' rather than via "smilecdr.cdrNodes"
                  Then the generated certificate specs will not be in the context. This doesn't matter though
                  as the service only gets rendered when called via the nodes helper. There may be some
                  structural refactoring required here to make this easier to work with.
                  For now, this 'hack' works without breaking anything :) */ -}}
            {{- if hasKey $cdrNodeValues "certificates" -}}
              {{- $certificates := $cdrNodeValues.certificates -}}
              {{- $theCertificateName := $theService.tls.tlsCertificate -}}

              {{- /* Determine certificate name if using the default */ -}}
              {{- if eq (lower $theService.tls.tlsCertificate) "default" -}}
                {{- $defaultCertificateName := (include "certmanager.defaultCertificate" $certificates) -}}
                {{- if ne $defaultCertificateName "" -}}
                  {{- $theCertificateName = $defaultCertificateName -}}
                {{- else -}}
                  {{- fail (printf "You are using the default TLS certificate, but no default has been defined and enabled.") -}}
                {{- end -}}
              {{- /* If not using default, check tht certificate name has been defined and enabled */ -}}
              {{- else -}}
                {{- if not (hasKey $certificates $theCertificateName) -}}
                  {{- fail (printf "You have specified a TLS certificate, `%s`, that has not been defined and enabled." $theCertificateName) -}}
                {{- end -}}
              {{- end -}}

              {{- /* Get a copy of the certificate spec to work with */ -}}

              {{- $theCertificate := get $certificates $theCertificateName -}}
              {{- $theCertificateSecretName := $theCertificate.name -}}
              {{- $keystoreCredentialsSecret := $theCertificate.spec.keystores.pkcs12.passwordSecretRef -}}
              {{- $keystoreCredentialValue := "" -}}

              {{- /* Determine how to pass in the keystore secret*/ -}}
              {{- $keystorePasswordConfig := default (dict) $theCertificate.keystorePassword -}}

              {{- if and (hasKey $keystorePasswordConfig "useSecret") (not $keystorePasswordConfig.useSecret) -}}
                {{- /* Secret is disabled - Currently not supported */ -}}
                {{- fail "Disabling secret for cert-manager generated keystores is not currently supported. " -}}
                {{- $keystoreCredentialValue = default "changeit" $keystorePasswordConfig.valueOverride -}}
              {{- else -}}
                {{- $keystoreCredentialValue = printf "#{env['%s_TLS_KEYSTORE_PASS']}" (upper $theCertificateSecretName) -}}
              {{- end -}}

              {{- $keystoreFileName := printf "%s-tls-keystore.p12" $theCertificateSecretName -}}
              {{- $_ := set $theModuleConfig "tls.enabled" true -}}
              {{- $_ := set $theModuleConfig "tls.keystore.file" (printf "classpath:tls/%s" $keystoreFileName) -}}
              {{- $_ := set $theModuleConfig "tls.keystore.password" $keystoreCredentialValue -}}
              {{- $_ := set $theModuleConfig "tls.keystore.keyalias" 1 -}}
              {{- $_ := set $theModuleConfig "tls.keystore.keypass" $keystoreCredentialValue -}}

              {{- /* Some other required module config if using TLS */ -}}
              {{- $_ := set $theModuleConfig "https_forwarding_assumed" false -}}
              {{- $_ := set $theModuleConfig "respect_forward_headers" false -}}

              {{- /* If using AWS ALB, then we need to disable SNI checking in the Smile CDR module.
                  This may be overridden using `extraCdrConfig` */ -}}
              {{ if has "aws-lbc-alb" $enabledIngressTypes -}}
                {{- $_ := set $theModuleConfig "tls_debug_disable_sni_check" true -}}
              {{- end -}}

              {{- range $theExtraConfigName, $theExtraConfigItem := $moduleExtraConfig -}}
                {{- $_ := set $theModuleConfig $theExtraConfigName $theExtraConfigItem -}}
              {{- end -}}

            {{- end -}}
          {{- end -}}{{- /* end of if $theService.tls.enabled */ -}}
        {{- end -}}{{- /* end of if $serviceHasEndpoint */ -}}
      {{- end -}}

      {{- /* Add configuration for RDS IAM auth */ -}}
      {{- $dbConnections := (include "smilecdr.database.external.connections" $) | fromYamlArray -}}
      {{- range $theDBConnectionSpec := $dbConnections -}}
        {{- if and (eq $theDBConnectionSpec.connectionConfig.authentication.type "iam") (has $theModuleName $theDBConnectionSpec.modules) -}}
          {{- if eq $theDBConnectionSpec.connectionConfig.authentication.iamProvider "aws" -}}
            {{- /* Enable IAM authentication */ -}}
            {{- $_ := set $theModuleSpec.config "db.auth_using_iam" true -}}
            {{- /* Set this to 15 mins max as per https://smilecdr.com/docs/database_administration/iam_auth.html */ -}}
            {{- /* If it's already defined in this module, use that value if it's under the iam Token Lifetime value */ -}}
            {{- $connMaxlifetimeMillis := $theDBConnectionSpec.connectionConfig.authentication.iamTokenLifetimeMillis -}}
            {{- /* Need to unflatten as we don't know if this setting is configured flattened or not in the values file */ -}}
            {{- $unFlattenedConfig := include "sdhCommon.unFlattenDict" $theModuleSpec.config | fromYaml -}}
            {{- if hasKey ((($unFlattenedConfig).db).connectionpool).maxlifetime "millis" -}}
              {{- $connMaxlifetimeMillis = min $unFlattenedConfig.db.connectionpool.maxlifetime.millis $theDBConnectionSpec.connectionConfig.iamTokenLifetimeMillis -}}
            {{- end -}}
            {{- $_ := set $theModuleSpec.config "db.connectionpool.maxlifetime.millis" $connMaxlifetimeMillis -}}
            {{- /* Do not provide password when using IAM auth */ -}}
            {{- $_ := unset $theModuleSpec.config "db.password" -}}
          {{- else -}}
            {{- fail (printf "IAM not supported by `%s` provider." $theDBConnectionSpec.connectionConfig.authentication.iamProvider) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- /* Add configuration for Secrets Manager auth */ -}}
      {{- range $theDBConnectionSpec := $extDBConnections -}}
        {{- if and (eq $theDBConnectionSpec.connectionConfig.authentication.type "secretsmanager") (has $theModuleName $theDBConnectionSpec.modules) -}}
          {{- if eq $theDBConnectionSpec.connectionConfig.authentication.secretsManagerProvider "aws" -}}
            {{- /* Enable Secrets Manager authentication */ -}}
            {{- $_ := set $theModuleSpec.config "db.secrets_manager" "AWS" -}}
            {{- $_ := set $theModuleSpec.config "db.username" $theDBConnectionSpec.connectionConfig.authentication.secretArn  -}}
            {{- /* $_ := set $theModuleSpec.config "db.url" "jdbc-secretsmanager:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require" */ -}}
            {{- /* TODO: Update Secrets Manager configuration as so:
                * If using Secrets Manager secrets with the appropriate structure, all DB connection details can be provided from the secret. You do not need to mount the secret into the pod.
                * It's also possible to provide DB connection details using a Secret mounted via SSCSI
                * It's also possible to provide DB connection details directly in the values file.
                Of course, using Secrets Manager would be the preferred option here as no connection configuration needs to be brought into the pod, other than the Secret ARN
                This means there are various options of configuration that will work with this.
                */ -}}
            {{- $_ := set $theModuleSpec.config "db.url" $theDBConnectionSpec.connectionConfig.authentication.secretArn -}}
            {{- /* Do not provide password when using SecretsManager auth */ -}}
            {{- $_ := unset $theModuleSpec.config "db.password" -}}
          {{- else -}}
            {{- fail (printf "Secretsmanager secrets not supported by `%s` provider." $theDBConnectionSpec.connectionConfig.authentication.secretsManagerProvider) -}}
          {{- end -}}
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
{{- define "smilecdr.endpointModulePrefixes" -}}
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
  {{- $extDBConnections := include "smilecdr.database.external.connections" $ | fromYamlArray -}}
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
    {{- $numCrunchyUsersWithModules := 0 -}}
    {{- range $crunchyUser := $.Values.database.crunchypgo.users -}}
      {{- if hasKey $crunchyUser "module" -}}
        {{- $numCrunchyUsersWithModules = add $numCrunchyUsersWithModules 1 -}}
      {{- end -}}
    {{- end -}}

    {{- $numDBConnectionModuleAssignments := 0 -}}
    {{- range $extConnectionConfig := $extDBConnections -}}
      {{- $numDBConnectionModuleAssignments = add $numDBConnectionModuleAssignments (len $extConnectionConfig.modules) -}}
    {{- end -}}
    {{- if or (and $.Values.database.crunchypgo.enabled (gt $numCrunchyUsersWithModules 1)) (gt $numDBConnectionModuleAssignments 1) -}}
      {{- $envDBPrefix = printf "%s_" ( upper $theModuleName ) -}}
    {{- end -}}

    {{- /* Get flattened configuration */ -}}
    {{- $flattenedConf := include "sdhCommon.flattenConf" $theModuleSpec.config | fromYaml -}}

    {{- /* Module Configuration */ -}}
    {{- range $theConfigItemName, $theConfigItemValue := $flattenedConf -}}
      {{- $theConfigItemValue = toString $theConfigItemValue -}}

      {{- /* TODO: Move all of these special use cases into separate config parsing template. */ -}}

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
