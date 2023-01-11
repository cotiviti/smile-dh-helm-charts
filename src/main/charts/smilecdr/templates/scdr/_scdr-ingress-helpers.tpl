{{/*
Define Ingress annotations
This combines all default per-provider annotations
(Specified by .Values.ingress.type) as well as any
annotations passed in via .Values.ingress.annotations
*/}}
{{- define "ingress.annotations" -}}
  {{- $includes := ( include "ingress.autoAnnotations" . | fromYaml) -}}
  {{- with .Values.ingress.annotations -}}
    {{- $includes = merge $includes . -}}
  {{- end -}}
  {{- if gt (len $includes ) 0 -}}
    {{- range $k, $v := $includes -}}
      {{- printf "%s: %v\n" $k ($v | quote) -}}
    {{- end -}}
  {{- else -}}
    {{- printf "{}" -}}
  {{- end -}}
{{- end -}}

{{/*
Predefined default Ingress annotations based on
specified cloud provider
*/}}
{{- define "ingress.autoAnnotations" -}}
{{- if eq "azure-appgw" .Values.ingress.type -}}
{{- /*
Azure Application Gateway Annotations (No Nginx Ingress)
*/ -}}
kubernetes.io/ingress.class: {{ default "azure/application-gateway" .Values.ingress.ingressClassNameOverride }}
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
kubernetes.io/ingress.class: {{ default "nginx" .Values.ingress.ingressClassNameOverride }}
nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
{{- else if eq "aws-lbc-alb" .Values.ingress.type -}}
{{- /*
AWS Load Balancer Controller Annotations (ALB)
Be sure to specify all required annotations
*/ -}}
kubernetes.io/ingress.class: {{ default "alb" .Values.ingress.ingressClassNameOverride }}
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
