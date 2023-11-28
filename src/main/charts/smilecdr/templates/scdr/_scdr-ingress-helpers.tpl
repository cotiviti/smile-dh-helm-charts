{{/*
Define Ingress annotations
This combines all default per-provider annotations
(Specified by .Values.ingress.type) as well as any
annotations passed in via .Values.ingress.annotations
*/}}
{{- define "smilecdr.ingress.annotations" -}}
  {{- $annotations := ( include "ingress.autoAnnotations" . | fromYaml) -}}
  {{- with .Values.ingress.annotations -}}
    {{- $annotations = merge . $annotations -}}
  {{- end -}}
  {{- /* TODO: Find a more elegant way to fix the quoting here */ -}}
  {{- if gt (len $annotations ) 0 -}}
    {{- range $k, $v := $annotations -}}
      {{- printf "%s: %v\n" $k ($v | quote) -}}
    {{- end -}}
  {{- else -}}
    {{- printf "{}" -}}
  {{- end -}}
{{- end -}}


{{/*
Default Ingress class name based on specified cloud provider
*/}}
{{- define "ingress.className" -}}
  {{- $ingressClassName := "" -}}
  {{- if eq "azure-appgw" .Values.ingress.type -}}
    {{- $ingressClassName = "azure/application-gateway" -}}
  {{- else if eq "nginx-ingress" .Values.ingress.type -}}
    {{- $ingressClassName = "nginx" -}}
  {{- else if eq "aws-lbc-alb" .Values.ingress.type -}}
    {{- $ingressClassName = "alb" -}}
  {{- end -}}
  {{- default $ingressClassName .Values.ingress.ingressClassNameOverride -}}
{{- end -}}

{{/*
Predefined default Ingress annotations based on
specified cloud provider
*/}}
{{- define "ingress.autoAnnotations" -}}
{{- $ingressClassName := include "ingress.className" . -}}
{{- if eq "azure-appgw" .Values.ingress.type -}}
{{- /*
Azure Application Gateway Annotations (No Nginx Ingress)
*/ -}}
kubernetes.io/ingress.class: {{ $ingressClassName }}
appgw.ingress.kubernetes.io/backend-protocol: http
appgw.ingress.kubernetes.io/cookie-based-affinity: "false"
appgw.ingress.kubernetes.io/use-private-ip: "false"
appgw.ingress.kubernetes.io/health-probe-interval: '6'
appgw.ingress.kubernetes.io/health-probe-timeout: '5'
appgw.ingress.kubernetes.io/health-probe-status-codes: 200-401
appgw.ingress.kubernetes.io/override-frontend-port: "443"
{{- else if eq "nginx-ingress" .Values.ingress.type -}}
{{- /*
Nginx Ingress Annotations
Note: Most of the general annotations are defined in the
nginx-ingress controller.
*/ -}}
kubernetes.io/ingress.class: {{ $ingressClassName }}
nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
{{- else if eq "aws-lbc-alb" .Values.ingress.type -}}
{{- /*
AWS Load Balancer Controller Annotations (ALB)
Be sure to specify all required annotations
*/ -}}
kubernetes.io/ingress.class: {{ $ingressClassName }}
alb.ingress.kubernetes.io/target-group-attributes: stickiness.enabled=false,stickiness.lb_cookie.duration_seconds=300
alb.ingress.kubernetes.io/backend-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-port: traffic-port
alb.ingress.kubernetes.io/healthcheck-path: /signin
alb.ingress.kubernetes.io/healthcheck-interval-seconds: '6'
alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
alb.ingress.kubernetes.io/success-codes: 200-401
alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
alb.ingress.kubernetes.io/ssl-policy: 'ELBSecurityPolicy-2016-08'
alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
alb.ingress.kubernetes.io/target-type: instance
alb.ingress.kubernetes.io/scheme: internet-facing
{{- end -}}
{{- end -}}

{{- /* Define hosts and rules for the default `Ingress` object.
    The result is a combination of defined hosts and
    enabled services from all CDR Nodes. */ -}}
{{- define "ingress.default.hosts" -}}
  {{- $hosts := dict -}}
  {{- $hostsList := list -}}
  {{- range $theNodeName, $theNodeCtx := include "smilecdr.nodes" . | fromYaml -}}
    {{- $theNodeSpec := $theNodeCtx.Values -}}
    {{- /* Get list of all hosts used by services in current CDR Node */ -}}
    {{- range $theServiceName, $theServiceSpec := $theNodeSpec.services -}}
      {{- /* Only include hosts for services that use the default `Ingress` object. */ -}}
      {{- /* Currently there is no handling for multiple or non-default `Ingress` objects. */ -}}
      {{- if $theServiceSpec.defaultIngress -}}
        {{- if not (hasKey $hosts $theServiceSpec.hostName) -}}
          {{- $hostObject := dict -}}
          {{- $_ := set $hostObject "host" $theServiceSpec.hostName -}}
          {{- $_ := set $hostObject "http" (dict "paths" (list)) -}}
          {{- $_ := set $hosts $theServiceSpec.hostName $hostObject -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- /* TODO: */ -}}

    {{- range $kHost, $vHost := $hosts -}}
      {{- $currentHost := dict -}}
      {{- $hostPaths := list -}}
      {{- range $theServiceName, $theServiceSpec := $theNodeSpec.services -}}
        {{- if and (eq $theServiceSpec.hostName $vHost.host) $theServiceSpec.defaultIngress -}}
          {{- $serviceObject := dict "name" $theServiceSpec.resourceName "port" (dict "number" $theServiceSpec.port) -}}
          {{- $pathObject := dict "path" $theServiceSpec.fullPath "pathType" "Prefix" "backend" (dict "service" $serviceObject) -}}
          {{- $hostPaths = append $hostPaths $pathObject -}}
        {{- end -}}
      {{- end -}}
      {{- $_ := set $vHost.http "paths" (concat $vHost.http.paths $hostPaths) -}}
    {{- end -}}
  {{- end -}}
  {{- /* Convert dict to list. */ -}}
  {{- range $kHost, $vHost := $hosts -}}
    {{- $hostsList = append $hostsList $vHost -}}
  {{- end -}}
  {{- $hostsList | toYaml -}}
{{- end -}}
