{{/*
Define extra details for SmileCDR
*/}}

{{/*
Define SmileCDR Node name
Currently only supports a single node, so we can remove it
  from the ConfigMap.
If there are 0 cdrNodes entries, set default to Masterdev
  this should not happen as we have the default values,
  but leaving it in code in case.
If there is 1 cdrNodes entry, set default to that value
  as it's from the default values file.
If there are 2 cdrNodes entries, custom values file has set
  a new entry, so use that.
If there are more than 2 cdrNodes entries, custom values, it
  will be unpredictable until we support multiple nodes. For
  now, it will just go through the range and use the last one.
*/}}
{{- define "smilecdr.nodeId" -}}
  {{- $nodeId := "Masterdev" -}}
  {{- if .Values.cdrNodes -}}
    {{- if eq (len .Values.cdrNodes) 1 -}}
      {{- range $key, $val := .Values.cdrNodes -}}
        {{- $nodeId = $key -}}
      {{- end -}}
    {{- /* If 2 or more entries, use any value that is not Masterdev */ -}}
    {{- else if gt (len .Values.cdrNodes) 1 -}}
      {{- range $key, $val := .Values.cdrNodes -}}
        {{- if ne $key "Masterdev" -}}
          {{- $nodeId = $key -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" $nodeId -}}
{{- end -}}

{{/*
Define SmileCDR DB Type
*/}}
{{- define "smilecdr.dbType" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "postgres" .Values.database.crunchypgo.type -}}
{{- else if and .Values.database.external.enabled -}}
{{- default "postgres" .Values.database.external.type -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define SmileCDR DB Port
*/}}
{{- define "smilecdr.dbPort" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- default "5432" .Values.database.crunchypgo.port -}}
{{- else if and .Values.database.external.enabled (eq .Values.database.external.dbType "postgres" ) -}}
{{- default "5432" .Values.database.external.port -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Ingress annotations
This combines all default per-provider annotations
(Specified by .Values.ingress.type) as well as any
extra annotations passed in via:
.Values.ingress.annotations or
.Values.ingress.extraAnnotations
*/}}
{{- define "ingress.annotations" -}}
  {{- $includes := ( include "ingress.autoAnnotations" . | fromYaml) -}}
  {{- with .Values.ingress.annotations -}}
    {{- $includes = merge $includes . -}}
  {{- end -}}
  {{- with .Values.ingress.extraAnnotations -}}
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
kubernetes.io/ingress.class: azure/application-gateway
appgw.ingress.kubernetes.io/backend-protocol: http
appgw.ingress.kubernetes.io/appgw-ssl-certificate: mysslcert
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
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
{{- else if eq "aws-lbc-alb" .Values.ingress.type -}}
{{- /*
AWS Load Balancer Controller Annotations (ALB)
Be sure to specify all required annotations
*/ -}}
kubernetes.io/ingress.class: alb
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

{{/*
Smile CDR Config Helpers
Creates config snippets.
*/}}
{{/*
Message Broker (ActiveMQ vs Kafka)
*/}}
{{- define "scdrcfg.messagebroker" -}}
{{- $brokerType := "EMBEDDED_ACTIVEMQ" -}}
{{- $kafkaBootstrap := "" -}}
{{- $kafkaSSLEnabled := "false" -}}
{{- if or .Values.messageBroker.strimzi.enabled .Values.messageBroker.external.enabled -}}
   {{- if .Values.messageBroker.strimzi.enabled -}}
    {{- $brokerType = "KAFKA" -}}
    {{- if .Values.messageBroker.strimzi.config.tls -}}
      {{- $kafkaBootstrap = printf "%s-kafka-bootstrap:9093" .Release.Name -}}
      {{- $kafkaSSLEnabled = "true" -}}
    {{- else -}}
      {{- $kafkaBootstrap = printf "%s-kafka-bootstrap:9092" .Release.Name -}}
    {{- end -}}
  {{- else if eq .Values.messageBroker.external.type "kafka" -}}
    {{- $brokerType = "KAFKA" -}}
    {{- $kafkaBootstrap = .Values.messageBroker.external.bootstrapAddress -}}
    {{- if .Values.messageBroker.external.tls -}}
      {{- $kafkaSSLEnabled = "true" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
module.clustermgr.config.messagebroker.type                         ={{ $brokerType }}
{{- if eq $brokerType "KAFKA" }}
module.clustermgr.config.kafka.bootstrap_address                    ={{ $kafkaBootstrap }}
module.clustermgr.config.kafka.ssl.enabled                          ={{ $kafkaSSLEnabled }}
module.clustermgr.config.kafka.consumer.properties.file             =classpath:/cdr_kafka_config/cdr-kafka-consumer-config.properties
module.clustermgr.config.kafka.producer.properties.file             =classpath:/cdr_kafka_config/cdr-kafka-producer-config.properties
{{- end }}
{{- end }}

{{/*
Smile CDR JVM settings helper
Creates JVM .
*/}}
{{- define "smilecdr.jvmargs" -}}
  {{- $jvmArgs := "-server" -}}
  {{- $jvmHeapBytes := ( include "k8s.suffixToValue" .Values.resources.requests.memory ) -}}
  {{- $jvmHeapBytes = mulf $jvmHeapBytes .Values.jvm.memoryFactor -}}
  {{- $jvmHeapBytesString := ( include "k8s.bytesToJavaSuffix" $jvmHeapBytes ) -}}
  {{- if .Values.jvm.xms -}}
    {{- $jvmArgs = print $jvmArgs " -Xms" $jvmHeapBytesString  -}}
  {{- end -}}
  {{- $jvmArgs = print $jvmArgs " -Xmx" $jvmHeapBytesString  -}}
  {{- range $v := .Values.jvm.args -}}
  {{- $jvmArgs = print $jvmArgs " " $v -}}
  {{- end -}}
  {{- print $jvmArgs | quote -}}
{{- end -}}

{{/*
K8s Quantity conversion
Takes a value with suffix and converts it to the
raw value
*/}}
{{- define "k8s.suffixToValue" -}}
  {{- $inVal := . | toString -}}
  {{- $rawVal := $inVal -}}
  {{- if hasSuffix "Gi" $inVal -}}
    {{- $rawVal = ( mulf 1024 1024 1024 ( trimSuffix "Gi" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "Mi" $inVal -}}
    {{- $rawVal = ( mulf 1024 1024 ( trimSuffix "Mi" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "Ki" $inVal -}}
    {{- $rawVal = ( mulf 1024 ( trimSuffix "Ki" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "G" $inVal -}}
    {{- $rawVal = ( mulf 1000000000 ( trimSuffix "G" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "M" $inVal -}}
    {{- $rawVal = ( mulf 1000000 ( trimSuffix "M" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "k" $inVal -}}
    {{- $rawVal = ( mulf 1000 ( trimSuffix "k" $inVal ) | float64 ) | int -}}
  {{- end -}}
  {{- printf "%d" ( $rawVal | float64 | int ) -}}
{{- end -}}

{{/*
K8s Quantity conversion
Takes a value with suffix and converts it to the
raw value
*/}}
{{- define "k8s.bytesToJavaSuffix" -}}
  {{- $bytes := . | int -}}
  {{- $Gi := mul 1024 1024 1024 -}}
  {{- $Mi := mul 1024 1024 -}}
  {{- $Ki := mul 1024 -}}
  {{- $outBytes := $bytes -}}
  {{- if gt $bytes $Mi -}}
    {{- $outBytes = printf "%sm" (trunc 5 ( divf $bytes $Mi | int | toString )) -}}
  {{- else if gt $bytes $Ki -}}
    {{- $outBytes = printf "%sk" (trunc 5 ( divf $bytes $Ki | int | toString )) -}}
  {{- end -}}
  {{- printf "%s" ( $outBytes | toString ) -}}
{{- end -}}
