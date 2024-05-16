{{/*
Define enabled services, extracted from the module definitions
Outputs as Serialized Yaml. If you need to parse the output, include it like so:
{{- $modules := include "smilecdr.services" . | fromYaml -}}
*/}}
{{- define "smilecdr.services" -}}
  {{- $services := dict -}}
  {{- /* TLS Certificate stuff... */ -}}
  {{- $tlsCertificates := (include "certmanager.certificates" . | fromYaml) -}}
  {{- $defaultCertificateName := (include "certmanager.defaultCertificate" $tlsCertificates) -}}

  {{- range $theServiceName, $theServiceSpec := (include "smilecdr.services.enabledServices" . | fromYaml) -}}
    {{- $theService := $theServiceSpec -}}
    {{- $theModuleName := $theServiceName -}}
    {{- $tlsSpec := $theServiceSpec.tls -}}

    {{- /* If TLS is enabled, check that the specified tlsCertificate configuration exists */ -}}
    {{- /* Validate tlsCertificate configuration exists. Does not make any changes */ -}}
    {{- if $tlsSpec.enabled -}}
      {{- if eq $tlsSpec.tlsCertificate "default" -}}
        {{- if not $defaultCertificateName -}}
          {{- fail (printf "You have not specified a TLS certificate for Module `%s` and there are no default certificates available.\nPlease either configure a default Certificate or choose from the available Certificates: %s" $theModuleName  (toString (keys $tlsCertificates))) -}}
        {{- end -}}
      {{- else -}}
        {{- if not (hasKey $tlsCertificates $tlsSpec.tlsCertificate) -}}
          {{- fail (printf "Certificate `%s` specified for Module `%s` does not exist. Please choose from the available Certificates: %s" $tlsSpec.tlsCertificate $theModuleName  (toString (keys $tlsCertificates))) -}}
        {{- end -}}
      {{- end -}}

      {{- /* Now we know the specified certificate is valid, we can populate other required settings. */ -}}
    {{- end -}}

    {{- /* Add to the services dict */ -}}
    {{- $_ := set $services $theServiceName $theServiceSpec -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}


{{- /* This helper is used to get the full list of services without any dependencies on
       other templates for auto-configuring the service spec. This is used to avoid some
       issues with circular dependencies */ -}}
{{- define "smilecdr.services.enabledServices" -}}
  {{- $services := dict -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- range $theModuleName, $theModuleSpec := $modules -}}
    {{- /* $theService := dict */ -}}
    {{- if ($theModuleSpec.service).enabled -}}
      {{- /* Temporary local dict to 'build' the service spec */ -}}
      {{- $theService := $theModuleSpec.service -}}
      {{/* Creating each module key, if enabled and if it has an enabled endpoint. */}}
      {{- $service := dict -}}
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
      {{- $_ := set $service "tls" $theService.tls -}}

      {{- /* Add to the service dict */ -}}
      {{- $_ := set $services $theModuleName $service -}}
    {{- end -}}
  {{- end -}}
  {{- $services | toYaml -}}
{{- end -}}
