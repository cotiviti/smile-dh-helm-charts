{{- define "smilecdr.ingresses" -}}
  {{- $ingresses := dict -}}

  {{- /* Configure the legacy default ingress */ -}}
  {{- if hasKey .Values "ingress" -}}
    {{- /* If values.ingress exists, continue to use that instead of values.ingresses.
      Also provide deprecation warning in `chartWarnings` template to use values.ingresses instead */ -}}
    {{- if or (not (hasKey .Values.ingress "enabled")) .Values.ingress.enabled -}}
      {{- $ingressSpec := deepCopy .Values.ingress -}}
      {{- $_ := set $ingressSpec "type" (default "nginx-ingress" (lower $ingressSpec.type) ) -}}

      {{- /* Set the ingress class name depending on the ingress type, or override value */ -}}
      {{- if hasKey $ingressSpec "ingressClassNameOverride" -}}
          {{- $_ := set $ingressSpec "ingressClassName" $ingressSpec.ingressClassNameOverride -}}
      {{- else -}}
        {{- /* Default ingress class name depending on the ingress type used */ -}}
        {{- if contains (lower $ingressSpec.type) "azure-gic azure-appgw" -}}
          {{- $_ := set $ingressSpec "ingressClassName" "azure/application-gateway" -}}
        {{- else if eq (lower $ingressSpec.type) "nginx-ingress" -}}
          {{- $_ := set $ingressSpec "ingressClassName" "nginx" -}}
        {{- else if eq (lower $ingressSpec.type) "aws-lbc-alb" -}}
          {{- $_ := set $ingressSpec "ingressClassName" "alb" -}}
        {{- else -}}
          {{- fail (printf "Ingress: Ingress type `%s` is not currently supported. Please choose from `nginx-ingress`, `aws-lbc-alb` or `azure-agic`." $ingressSpec.type) -}}
        {{- end -}}
      {{- end -}}

      {{- $_ := set $ingressSpec "name" "default" -}}
      {{- $_ := set $ingressSpec "defaultIngress" true -}}
      {{- $_ := set $ingressSpec "resourceSuffix" "scdr" -}}
      {{- $_ := set $ingresses "default" $ingressSpec -}}
      {{- /* Now we need to build the annotations and rules */ -}}
      {{- $annotations := ( include "smilecdr.ingress.autoAnnotations" (dict "ingressSpec" $ingressSpec) | fromYaml) -}}
      {{- /* Set legacy annotation with ingressClassName and then unset it so that it does not get included in the
          main ingress spec, as we are not using this part of the ingress spec if using this legacy ingress mechanism */ -}}
      {{- $_ := set $annotations "kubernetes.io/ingress.class" $ingressSpec.ingressClassName -}}
      {{- $_ := unset $ingressSpec "ingressClassName" -}}
      {{- with $ingressSpec.annotations -}}
        {{- $annotations = deepCopy (merge . $annotations) -}}
      {{- end -}}
      {{- /* Normalize annotation key names to cope with double-quoted annotations */ -}}
      {{- range $theAnnotationKey, $theAnnotationValue := $annotations -}}
        {{- $unquotedKey := trimAll "\"" $theAnnotationKey -}}
        {{- $unquotedValue := trimAll "\"" $theAnnotationValue -}}
        {{- if ne $unquotedKey $theAnnotationKey -}}
          {{- /* The annotation key is different to the 'unquoted' one, which means it's double quoted
              and needs replacing */ -}}
          {{- $_ := set $annotations (trimAll "\"" $theAnnotationKey) $unquotedValue -}}
          {{- $_ := unset $annotations $theAnnotationKey -}}
        {{- else if ne $unquotedValue $theAnnotationValue -}}
          {{- /* The annotation value is different to the 'unquoted' one, which means it's double quoted
              and needs replacing, even if the key was fine. */ -}}
          {{- $_ := set $annotations $theAnnotationKey $unquotedValue -}}
        {{- end -}}
      {{- end -}}
      {{- $_ := set $ingressSpec "annotations" $annotations -}}
    {{- end -}}

  {{- else if hasKey .Values "ingresses" -}}
    {{- /* Only call "smilecdr.cdrNodes" if the 'cdrNodes' key is still present
           This is because sometimes "smilecdr.ingresses" can be called out of
           context. In these cases (reference or validation) the cdrNodes is not
           required in this template.
           TODO: Fix this ugliness when we refactor template structure. */ -}}
    {{- $cdrNodes := dict -}}
    {{- if hasKey .Values "cdrNodes" -}}
      {{- $cdrNodes = include "smilecdr.cdrNodes" . | fromYaml  -}}
    {{- end -}}
    {{- $numEnabledIngresses := 0 -}}
    {{- $defaultIngressName := "" -}}
    {{- if .Values.ingresses.default.enabled -}}
      {{- $defaultIngressName = "default" -}}
    {{- end -}}
    {{- range $theIngressName, $theIngressSpec := .Values.ingresses -}}
      {{- if $theIngressSpec.enabled -}}
        {{- $numEnabledIngresses = add $numEnabledIngresses 1 -}}
        {{- /* Determine default ingress configuration */ -}}
        {{- if $theIngressSpec.defaultIngress  -}}
          {{- /* We can only allow a single ingress to be the default */ -}}
          {{- /* If default ingress is already defined AND we are not working on the default (As it has `defaultIngress` enabled by default)... */ -}}
          {{- if and $defaultIngressName (ne $theIngressName "default") -}}
            {{- $errMsg := (printf "Ingress: You are trying to set ingress `%s` as the default ingress,\n    but the ingress `%s` is already set as the default. You can only define a single ingress with `defaultIngress` set to true" $theIngressName $defaultIngressName) -}}
            {{- if eq "default" $defaultIngressName -}}
              {{- /* Suggest disabling the default ingress */ -}}
              {{- fail (printf "\n\n%s\n\nIf you are trying to create a new default ingress definition, consider disabling the original default ingress with `ingresses.default.enabled: false`" $errMsg) -}}
            {{- else -}}
              {{- fail (printf "\n\n%s\n" $errMsg) -}}
            {{- end -}}
          {{- else -}}
            {{- $defaultIngressName = $theIngressName -}}
          {{- end -}}
        {{- end -}}

        {{- /* Comment on why this is copied
            Possibly because we want to use/derive values without affecting the
            parent object? */ -}}
        {{- $ingressSpec := deepCopy $theIngressSpec -}}
        {{- $_ := set $ingressSpec "name" $theIngressName -}}


        {{- /* When upgrading from previous versions of the Helm Chart, multiple ingress support may replace
            existing ingress objects. This in turn may replace cloud provisioned load balancers which may be
            undesirable.
            This section allows overriding of the default ingress resource name so that it does not get
            replaced during an upgrade.
            */ -}}
        {{- if and (eq $theIngressName "default") $theIngressSpec.useLegacyResourceSuffix -}}
          {{- /* This is the default ingress object. Mark it accordingly. */ -}}
          {{- $_ := set $ingressSpec "resourceSuffix" "scdr" -}}
        {{- else -}}
          {{- $_ := set $ingressSpec "resourceSuffix" (printf "scdr-%s" (lower $theIngressName)) -}}
        {{- end -}}

        {{- /* Set the ingress class name depending on the ingress type, or override value */ -}}
        {{- if hasKey $ingressSpec "ingressClassNameOverride" -}}
            {{- $_ := set $ingressSpec "ingressClassName" $ingressSpec.ingressClassNameOverride -}}
        {{- else -}}
          {{- /* Default ingress class name depending on the ingress type used */ -}}
          {{- if contains (lower $ingressSpec.type) "azure-agic azure-appgw" -}}
            {{- $_ := set $ingressSpec "ingressClassName" "azure/application-gateway" -}}
          {{- else if eq (lower $ingressSpec.type) "nginx-ingress" -}}
            {{- $_ := set $ingressSpec "ingressClassName" "nginx" -}}
          {{- else if eq (lower $ingressSpec.type) "aws-lbc-alb" -}}
            {{- $_ := set $ingressSpec "ingressClassName" "alb" -}}
          {{- else -}}
            {{- fail (printf "Ingress: Ingress type `%s` is not currently supported. Please choose from `nginx-ingress`, `aws-lbc-alb` or `azure-agic`." $ingressSpec.type) -}}
          {{- end -}}
        {{- end -}}

        {{- /* Determine if the backend rules use HTTP or HTTPS */ -}}
        {{- /* Check for ALL nodes for TLS-enabled services */ -}}
        {{- /* TODO: Cleanup on refactor */ -}}
        {{- /* If the "smilecdr.modules" helper gets called 'directly' rather than via "smilecdr.cdrNodes"
                      Then the generated certificate specs will not be in the context. This doesn't matter though
                      as the service only gets rendered when called via the nodes helper. There may be some
                      structural refactoring required here to make this easier to work with.
                      For now, this 'hack' works without breaking anything :) */ -}}

        {{- $httpCount := 0 -}}
        {{- $httpsCount := 0 -}}

        {{- /* We need to check services in ALL CDR Nodes... */ -}}
        {{- range $theCdrNodeName, $theCdrNodeCtx := $cdrNodes -}}
          {{- $theCdrNodeSpec := $theCdrNodeCtx.Values -}}
          {{- range $theServiceName, $theServiceSpec := $theCdrNodeSpec.services -}}

            {{- /* First determine if this service uses this ingress */ -}}
            {{- $serviceUsesIngress := false -}}

            {{- /* The default ingress case: */ -}}
            {{- if and $ingressSpec.defaultIngress $theServiceSpec.defaultIngress -}}
              {{- $serviceUsesIngress = true -}}
            {{- /* The "service.ingresses" case */ -}}
            {{- else -}}
              {{- with $theServiceSpec.ingresses -}}
                {{- if hasKey . $ingressSpec.name -}}
                  {{- $serviceIngress := get . $ingressSpec.name -}}
                  {{- if $serviceIngress.enabled -}}
                    {{- $serviceUsesIngress = true -}}
                  {{- end -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}

            {{- /* If the service has this ingress in its list of ingresses */ -}}
            {{- if $serviceUsesIngress -}}
              {{- if $theServiceSpec.tls.enabled -}}
                {{- /* This service is using the current ingress, and is using TLS. */ -}}
                {{- $httpsCount = add1 $httpsCount -}}
              {{- else -}}
                {{- $httpCount = add1 $httpCount -}}
              {{- end -}}

              {{- if and (gt $httpCount 0) (gt $httpsCount 0) -}}
                {{- fail "Mixed ingress backend schemas" -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}

        {{- /* Set encryption scheme for backend for this ingress
               The actual annotations will be added in "smilecdr.ingress.autoAnnotations" */ -}}
        {{- if gt $httpsCount 0 -}}
          {{- $_ := set $ingressSpec "backendEncrypted" true -}}
          {{- if gt $httpCount 0 -}}
            {{- fail (printf "Mixed ingress backend schemas. Guard assertion found. This should not happen!") -}}
          {{- end -}}
        {{- else -}}
          {{- /* TODO: Add this when we turn on https backends by default -}}
          {{- $_ := set $ingressSpec. "encrypted-backend" false */ -}}
        {{- end -}}

        {{- /* Now we need to build the annotations and rules */ -}}
        {{- $annotations := ( include "smilecdr.ingress.autoAnnotations" (dict "ingressSpec" $ingressSpec) | fromYaml) -}}
        {{- with $ingressSpec.annotations -}}
          {{- $annotations = deepCopy (merge . $annotations) -}}
        {{- end -}}
        {{- /* Normalize annotation key names to cope with double-quoted annotations */ -}}
        {{- range $theAnnotationKey, $theAnnotationValue := $annotations -}}
          {{- $unquotedKey := trimAll "\"" $theAnnotationKey -}}
          {{- $unquotedValue := trimAll "\"" $theAnnotationValue -}}
          {{- if ne $unquotedKey $theAnnotationKey -}}
            {{- /* The annotation key is different to the 'unquoted' one, which means it's double quoted
                and needs replacing */ -}}
            {{- $_ := set $annotations (trimAll "\"" $theAnnotationKey) $unquotedValue -}}
            {{- $_ := unset $annotations $theAnnotationKey -}}
          {{- else if ne $unquotedValue $theAnnotationValue -}}
            {{- /* The annotation value is different to the 'unquoted' one, which means it's double quoted
                and needs replacing, even if the key was fine. */ -}}
            {{- $_ := set $annotations $theAnnotationKey $unquotedValue -}}
          {{- end -}}
        {{- end -}}
        {{- $_ := set $ingressSpec "annotations" $annotations -}}
        {{- $_ := set $ingresses $theIngressName $ingressSpec -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- fail (printf "\n\nIngress: You must provide `values.ingresses` or `values.ingress`(deprecated) definitions.\n") -}}
  {{- end -}}
  {{- $ingresses | toYaml -}}
{{- end -}}

{{/*
Predefined default Ingress annotations based on
specified cloud provider
*/}}
{{- define "smilecdr.ingress.autoAnnotations" -}}
  {{- /* This template requires a dict with an ingressSpec object */ -}}
  {{- if not (hasKey . "ingressSpec") -}}
    {{- fail (printf "HelperError: Template `smilecdr.ingress.autoAnnotations` must be called with a dict with an `ingressSpec` object.\nThe provided context was:\n%s" (toPrettyJson .)) -}}
  {{- end -}}
  {{- $ingressSpec := get . "ingressSpec" -}}
  {{- $annotations := dict -}}

  {{- $backendProtocol := "HTTP" -}}
  {{- if $ingressSpec.backendEncrypted -}}
    {{- $backendProtocol = "HTTPS" -}}
  {{- end -}}

  {{- if contains (lower $ingressSpec.type) "azure-agic azure-appgw" -}}
    {{- /*
    Azure Application Gateway Annotations (No Nginx Ingress)
    */ -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/backend-protocol" (lower $backendProtocol) -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/cookie-based-affinity" "false" -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/use-private-ip" "false" -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-interval" "6" -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-timeout" "5" -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/health-probe-status-codes" "200" -}}
    {{- $_ := set $annotations "appgw.ingress.kubernetes.io/override-frontend-port" "443" -}}
  {{- else if eq (lower $ingressSpec.type) "nginx-ingress" -}}
    {{- /*
    Nginx Ingress Annotations
    Note: Most of the general annotations are defined in the
    nginx-ingress controller.
    */ -}}
    {{- if eq $backendProtocol "HTTPS" -}}
      {{- $_ := set $annotations "nginx.ingress.kubernetes.io/backend-protocol" $backendProtocol -}}

      {{- /* The below annotation does not currently work and may be addressed in some upcoming release of Ingress-Nginx.
            See: https://github.com/kubernetes/ingress-nginx/issues/8633#issuecomment-2094105356 */ -}}
      {{- /* $_ := set $annotations "nginx.ingress.kubernetes.io/proxy-ssl-protocols" "TLSv1.3" */ -}}
      {{- /* In the meantime, need to set via configuration-snippet if not set globally on the ingress-nginx configuration */ -}}
      {{- if $ingressSpec.tls13NginxConfigSnippet -}}
        {{- $nginxCipherConfig := "proxy_ssl_protocols TLSv1.3;" -}}
        {{- $_ := set $annotations "nginx.ingress.kubernetes.io/configuration-snippet" $nginxCipherConfig -}}
      {{- end -}}

    {{- end -}}
    {{- $_ := set $annotations "nginx.ingress.kubernetes.io/force-ssl-redirect" "true" -}}
  {{- else if eq (lower $ingressSpec.type) "aws-lbc-alb" -}}
    {{- /*
    AWS Load Balancer Controller Annotations (ALB)
    Be sure to specify all required annotations
    */ -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/backend-protocol" $backendProtocol -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/healthcheck-protocol" $backendProtocol -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/healthcheck-port" "traffic-port" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/healthcheck-interval-seconds" "6" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" "5" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/success-codes" "200" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/listen-ports" "[{\"HTTPS\":443}]" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/ssl-policy" "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/ssl-redirect" "443" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/target-type" "ip" -}}
    {{- $_ := set $annotations "alb.ingress.kubernetes.io/scheme" "internet-facing" -}}
  {{- end -}}
  {{ $annotations | toYaml }}
{{- end -}}

{{- /* Define rules for any given `Ingress` object.
    The result is a combination of defined hosts and
    enabled services from all CDR Nodes. */ -}}
{{- define "smilecdr.ingress.rules" -}}
  {{- /* Determine rules for given ingress object
    This code needs to reference the module configurations for all CDR nodes so it can determine if
    it has been selected by a given module.
    This is a contextual template so it needs to be provided with the root context as well as the ingress spec */ -}}
  {{- $cdrNodes := get . "cdrNodes" -}}
  {{- $ingressSpec := get . "ingressSpec" -}}
  {{- $hostselectors := dict -}}
  {{- $ingressRules := list -}}

  {{- range $theCdrNodeName, $theCdrNodeCtx := $cdrNodes -}}
    {{- $theCdrNodeSpec := $theCdrNodeCtx.Values -}}
    {{- /* Get list of all hosts used by services in current CDR Node */ -}}
    {{- range $theServiceName, $theServiceSpec := $theCdrNodeSpec.services -}}
      {{- /* Determine if the service is using the provided `ingressSpec`. Only include hosts if it is. */ -}}

      {{- /* First determine if this service uses this ingress */ -}}
      {{- $serviceUsesIngress := false -}}

      {{- /* The default ingress case: */ -}}
      {{- if and $ingressSpec.defaultIngress $theServiceSpec.defaultIngress -}}
        {{- $serviceUsesIngress = true -}}
      {{- /* The "service.ingresses" case */ -}}
      {{- else -}}
        {{- with $theServiceSpec.ingresses -}}
          {{- if hasKey . $ingressSpec.name -}}
            {{- $serviceIngress := get . $ingressSpec.name -}}
            {{- if $serviceIngress.enabled -}}
              {{- $serviceUsesIngress = true -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- if $serviceUsesIngress -}}
        {{- /* If host is not already in the list, add it */ -}}
        {{- $ruleObject := dict -}}
        {{- if not (hasKey $hostselectors $theServiceSpec.hostName) -}}
          {{- $_ := set $ruleObject "host" $theServiceSpec.hostName -}}
          {{- $_ := set $ruleObject "http" (dict "paths" (list)) -}}
          {{- $_ := set $hostselectors $theServiceSpec.hostName $ruleObject -}}

        {{- else -}}
          {{- $ruleObject = get $hostselectors $theServiceSpec.hostName -}}
        {{- end -}}

        {{- /* Add the path entry for this service */ -}}
        {{- $serviceObject := dict "name" $theServiceSpec.resourceName "port" (dict "number" $theServiceSpec.port) -}}
        {{- $pathObject := dict "path" $theServiceSpec.fullPath "pathType" "Prefix" "backend" (dict "service" $serviceObject) -}}
        {{- $hostPaths := get $ruleObject.http "paths" -}}
        {{- $hostPaths := append $hostPaths $pathObject -}}
        {{- /* $hostPaths := append $ruleObject.http.paths $pathObject */ -}}
        {{- $_ := set $ruleObject.http "paths" $hostPaths -}}
        {{- /* $_ := set $hostselectors $theServiceSpec.hostName $ruleObject */ -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Convert dict to list. */ -}}
  {{- range $kHost, $vHost := $hostselectors -}}
    {{- $ingressRules = append $ingressRules $vHost -}}
  {{- end -}}
  {{- $ingressRules | toYaml -}}
{{- end -}}

{{- /* Define tls configuration for any given `Ingress` object.
    The result is a combination of defined hosts and
    available tls configurations */ -}}
{{- define "smilecdr.ingress.tls.config" -}}
  {{- /* Determine rules for given ingress object
    This code needs to reference the module configurations for all CDR nodes so it can determine if
    it has been selected by a given module.
    This is a contextual template so it needs to be provided with the root context as well as the ingress spec */ -}}
  {{- $cdrNodes := get . "cdrNodes" -}}
  {{- $ingressSpec := get . "ingressSpec" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $issuerConfig := dict -}}
  {{- $ingressTLSConfig := dict -}}
  {{- $hostList := list -}}
  {{- $certManagerAnnotations := dict -}}

  {{- if ($ingressSpec.tlsConfig).enabled -}}
    {{- $issuerResourceName := "" -}}
    {{- if and (hasKey $ingressSpec.tlsConfig "issuerConfiguration") (hasKey $ingressSpec.tlsConfig "existingIssuer") -}}
      {{- fail (printf "You have defined `issuerConfiguration` and `existingIssuer` in your `%s` Ingress TLS configuration. Pleas use one or the other." $ingressSpec.name) -}}
    {{- end -}}

    {{- if hasKey $ingressSpec.tlsConfig "existingIssuer" -}}
      {{- /* Get referenced existing issuer */ -}}
      {{- $issuerResourceName = $ingressSpec.tlsConfig.existingIssuer -}}
    {{- else -}}
      {{- /* Get referenced issuer congfiguration, or use the default issuer congfiguration */ -}}
      {{- $enabledIssuerConfigs := include "certmanager.issuers" $rootCTX | fromYaml -}}
      {{- $currentIssuerConfig := get $enabledIssuerConfigs (default "default" $ingressSpec.tlsConfig.issuerConfiguration) -}}
      {{- if $currentIssuerConfig.enabled -}}
        {{- /* We are using a valid Issuer configuration which has been enabled.
              Set the issuer and enable further generation of the `ingress.spec.tls` configuration */ -}}
        {{- $issuerResourceName = (include "certmanager.issuer.resourceName" (dict "issuerSpec" $currentIssuerConfig "rootCTX" $rootCTX)) -}}
      {{- else -}}
        {{- fail (printf "Ingress configuration `%s` is trying to use a certificate Issuer configuration that does not exist or is not enabled.\n\tDisable the Ingress tlsConfig or enable the Issuer" $ingressSpec.name) -}}
      {{- end -}}
    {{- end -}}
    {{- $_ := set $certManagerAnnotations "cert-manager.io/issuer" $issuerResourceName -}}
  {{- end -}}

  {{- if hasKey $certManagerAnnotations "cert-manager.io/issuer" -}}
    {{- /* The ingressSpec.tls needs a list of hosts used in the certificate that will be used by this ingress. */ -}}
    {{- range $theCdrNodeName, $theCdrNodeCtx := $cdrNodes -}}
      {{- $theCdrNodeSpec := $theCdrNodeCtx.Values -}}
      {{- /* Get list of all hosts used by services in current CDR Node
             We get this from the service definitions. */ -}}
      {{- range $theServiceName, $theServiceSpec := $theCdrNodeSpec.services -}}
        {{- /* Determine if the service is using the provided `ingressSpec`. Only include hosts if it is. */ -}}

        {{- /* First determine if this service uses this ingress */ -}}
        {{- $serviceUsesIngress := false -}}

        {{- /* The default ingress case: */ -}}
        {{- if and $ingressSpec.defaultIngress $theServiceSpec.defaultIngress -}}
          {{- $serviceUsesIngress = true -}}
        {{- /* The "service.ingresses" case */ -}}
        {{- else -}}
          {{- with $theServiceSpec.ingresses -}}
            {{- if hasKey . $ingressSpec.name -}}
              {{- $serviceIngress := get . $ingressSpec.name -}}
              {{- if $serviceIngress.enabled -}}
                {{- $serviceUsesIngress = true -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}

        {{- if $serviceUsesIngress -}}
          {{- /* The host for this service is used by this ingress, so add it. */ -}}
          {{- $hostList = uniq (append $hostList $theServiceSpec.hostName) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- /* Prepare tls config dict to return */ -}}
    {{- $defaultSecretName := include "smilecdr.resourceName" (dict "name" (printf "%s-ingress-tls" $ingressSpec.name ) "rootCTX" $rootCTX) -}}
    {{- $secretName := default $defaultSecretName $ingressSpec.tlsConfig.secretNameOverride -}}
    {{- $_ := set $ingressTLSConfig "tlsSpec" (list (dict "hosts" $hostList "secretName" $secretName)) -}}
    {{- $_ := set $ingressTLSConfig "annotations" $certManagerAnnotations -}}
  {{- else -}}
    {{- /* Prepare empty tls config dict to return */ -}}
    {{- $_ := set $ingressTLSConfig "notls" "disabled"  -}}
  {{- end -}}

  {{- $ingressTLSConfig | toYaml -}}
{{- end -}}
