{{/*
Define extra details for SmileCDR
*/}}
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
Define SmileCDR DB secret
*/}}
{{- define "smilecdr.dbSecretName" -}}
{{- if .Values.database.crunchypgo.enabled -}}
{{- $crunchyUserName := default "smilecdr" .Values.database.crunchypgo.userName -}}
{{- printf "%s-pguser-%s" .Release.Name $crunchyUserName }}
{{- else if and .Values.database.external.enabled -}}
{{- default "changemepls" .Values.database.external.secretName -}}
{{- else -}}
{{- "changemepls" -}}
{{- end -}}
{{- end -}}

{{/*
Define Ingress Load Balancer Annotations
*/}}
{{- define "ingress.annotations" -}}
{{/*
Azure Application Gateway Annotations (No Nginx Ingress)
*/}}
{{- if eq "azure-appgw" .Values.ingress.type -}}
kubernetes.io/ingress.class: azure/application-gateway
appgw.ingress.kubernetes.io/backend-protocol: http
appgw.ingress.kubernetes.io/appgw-ssl-certificate: mysslcert
appgw.ingress.kubernetes.io/cookie-based-affinity: "false"
appgw.ingress.kubernetes.io/use-private-ip: "false" 
appgw.ingress.kubernetes.io/health-probe-interval: '6'
appgw.ingress.kubernetes.io/health-probe-timeout: '5'
appgw.ingress.kubernetes.io/health-probe-status-codes: 200-401
appgw.ingress.kubernetes.io/override-frontend-port: "443"
{{/*
AWS Load Balancer Controller Annotations (Nginx + NLB)
Note: Most of the general annotations are defined in the
nginx-ingress controller.
*/}}
{{- else if eq "aws-lbc-nlb" .Values.ingress.type -}}
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
{{- else -}}
{}
{{ end }}
{{- with .Values.ingress.annotations }}
{{- toYaml . }}
{{ end }}
{{- with .Values.ingress.extraAnnotations }}
{{- toYaml . }}
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
{{- if .Values.kafka.enabled -}}
module.clustermgr.config.messagebroker.type                         =KAFKA
module.clustermgr.config.kafka.bootstrap_address                    ={{ .Values.kafka.bootstrapAddress }}
module.clustermgr.config.kafka.group_id                             =smilecdr
module.clustermgr.config.kafka.auto_commit                          =false
module.clustermgr.config.kafka.validate_topics_exist_before_use     =false
module.clustermgr.config.kafka.ack_mode                             =MANUAL
module.clustermgr.config.kafka.ssl.enabled                          =false
module.clustermgr.config.kafka.security.protocol                    =SASL_SSL
module.clustermgr.config.kafka.sasl.mechanism                       =PLAIN
module.clustermgr.config.kafka.sasl.jaas.config                     =org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://nalchbp-deveus-evhu2.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=PBIo3TfNC4h/WHkC+znD9LOJWET1b0svJQwotJ9R1Q8=";
module.clustermgr.config.messagebroker.channel_naming.prefix        ={{ .Values.kafka.channelPrefix }}
module.persistence.config.subscription.consumers_per_matching_queue =2
module.persistence.config.subscription.consumers_per_delivery_queue =5
{{- else -}}
module.clustermgr.config.messagebroker.type                         =EMBEDDED_ACTIVEMQ
{{- end -}}
{{- end -}}