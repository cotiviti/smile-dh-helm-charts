{{/*
This helper file contains templates that assist in generating the
Smile CDR configuration file
*/}}

{{/*
This template defines the text of the main config file.
As it stands right now, it pulls in details from multiple places and concatenates
them all into a readable config file, complete with section headers.
*/}}
{{- define "smilecdr.cdrConfigText" -}}
  {{- $moduleText := "" -}}
  {{- $separatorText := "################################################################################" -}}
  {{/* Main Node Config Section */}}
  {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
  {{- $moduleText = printf "%s# Node Configuration\n" $moduleText -}}
  {{- $moduleText = printf "%s%s\n" $moduleText $separatorText -}}
  {{- $moduleText = printf "%snode.id \t= %s\n" $moduleText (include "smilecdr.nodeId" .) -}}
  {{- $nodeSettings := (include "smilecdr.nodeSettings" . | fromYaml) -}}
  {{- if ((include "smilecdr.nodeSettings" . | fromYaml).config).database -}}
    {{- $moduleText = printf "%snode.propertysource \t= %s\n" $moduleText "DATABASE" -}}
    {{- $moduleText = printf "%snode.config.locked \t= false\n" $moduleText -}}
  {{- else if ((include "smilecdr.nodeSettings" . | fromYaml).config).troubleshooting -}}
    {{- $moduleText = printf "%snode.propertysource \t= %s\n" $moduleText "PROPERTIES_UNLOCKED" -}}
    {{- $moduleText = printf "%snode.config.locked \t= false\n" $moduleText -}}
  {{- else -}}
    {{- $moduleText = printf "%snode.propertysource \t= %s\n" $moduleText "PROPERTIES" -}}
    {{- $moduleText = printf "%snode.config.locked \t= %v\n" $moduleText (ternary ($nodeSettings.config).locked true (and (hasKey $nodeSettings "config") (hasKey $nodeSettings.config "locked"))) -}}
  {{- end -}}
  {{- $moduleText = printf "%snode.security.strict \t= %v\n\n" $moduleText (default false (($nodeSettings).security).strict) -}}
  {{- if hasKey .Values "license" -}}
    {{- $moduleText = printf "%smodule.license.config.jwt_file \t= classpath:license.jwt\n" $moduleText -}}
  {{- end -}}
  {{- $moduleText = printf "%s%s\n\n" $moduleText (include "scdrcfg.messagebroker" .) -}}
  {{- $moduleText = printf "%s%s\n" $moduleText (include "smilecdr.cdrConfigTextBlob" .) -}}
  {{/* Include all modules */}}
  {{- $moduleText = printf "%s%s" $moduleText (include "smilecdr.modules.config.text" .) -}}
  {{- printf "%s\n" $moduleText -}}
{{- end -}}

{{/*
This just defines the text that is in a default Smile CDR config file.
It's not required, but included so that the resulting config file remains
familiar to Smile CDR adminitrators when inspecting it.
*/}}
{{- define "smilecdr.cdrConfigTextBlob" -}}
################################################################################
# Other Modules are Configured Below
################################################################################

# The following setting controls where module configuration is ultimately stored.
# When set to "DATABASE" (which is the default), the clustermgr configuration is
# always read but the other modules are stored in the database upon the first
# launch and their configuration is read from the database on subsequent
# launches. When set to "PROPERTIES", values in this file are always used.
#
# In other words, in DATABASE mode, the module definitions below this line are
# only used to seed the database upon the very first startup of the sytem, and
# will be ignored after that. In PROPERTIES mode, the module definitions below
# are read every time the system starts, and existing definitions and config are
# overwritten by what is in this file.
#
{{- end -}}

{{/*
Defines all the data that will be included in the configmap.
This is split out into a separate template so that it can be
used to generate the hash of the data.
*/}}
{{- define "smilecdr.cdrConfigData" -}}
cdr-config-Master.properties: |-
{{ include "smilecdr.cdrConfigText" . | indent 2 }}
{{- end -}}

{{/*
Generate a suffix that represents the SHA256 hash of the configMap
data if autoDeploy is enabled. Used for naming the configMap.
*/}}
{{- define "smilecdr.cdrConfigDataHashSuffix" -}}
  {{- if .Values.autoDeploy -}}
    {{- $data := ( include "smilecdr.cdrConfigData" .) -}}
    {{- printf "-%s" (sha256sum $data) -}}
  {{- end -}}
{{- end -}}

{{/*
Generate a suffix that represents the SHA256 hash of the provided
data if autoDeploy is enabled. Used for naming configMaps.
You must pass in a map with the root `Values` map and `data` to be hashed.
*/}}
{{- define "smilecdr.getConfigMapNameHashSuffix" -}}
  {{- if .Values.autoDeploy -}}
    {{- printf "-%s" (trunc 40 (sha256sum .data)) -}}
  {{- end -}}
{{- end -}}

{{/*
Message Broker Config Snippet (ActiveMQ vs Kafka)
TODO: Needs some rework. Specifically, a few Kafka config settings
are hard-coded in here.
*/}}
{{- define "scdrcfg.messagebroker" -}}
{{- $kafkaConfig := (include "kafka.config" . | fromYaml) -}}
  {{- if or $kafkaConfig.enabled -}}
module.clustermgr.config.messagebroker.type                         =KAFKA
module.clustermgr.config.kafka.bootstrap_address                    =#{env['KAFKA_BOOTSTRAP_ADDRESS']}
module.clustermgr.config.kafka.ssl.enabled                          =#{env['KAFKA_SSL_ENABLED']}
module.clustermgr.config.kafka.consumer.properties.file             =classpath:/cdr_kafka_config/cdr-kafka-consumer-config.properties
module.clustermgr.config.kafka.producer.properties.file             =classpath:/cdr_kafka_config/cdr-kafka-producer-config.properties
    {{- if not $kafkaConfig.autoCreateTopics }}
module.clustermgr.config.kafka.validate_topics_exist_before_use     =true
    {{- end }}
    {{- if eq $kafkaConfig.connection.type "tls" }}
      {{- if eq $kafkaConfig.authentication.type "iam" }}
module.clustermgr.config.kafka.security.protocol                    =SASL_SSL
      {{- else }}
module.clustermgr.config.kafka.security.protocol                    =SSL
      {{- end }}
      {{- if $kafkaConfig.publicca }}
module.clustermgr.config.kafka.ssl.truststore.location              =#{null}
module.clustermgr.config.kafka.ssl.truststore.password              =#{null}
      {{- else }}
module.clustermgr.config.kafka.ssl.truststore.location              =/home/smile/smilecdr/classes/client_certificates/kafka-ca-cert.p12
module.clustermgr.config.kafka.ssl.truststore.password              =#{env['KAFKA_BROKER_CA_CERT_PWD']}
      {{- end }}
    {{- end }}
    {{- if eq $kafkaConfig.authentication.type "tls" }}
module.clustermgr.config.kafka.ssl.keystore.location                =/home/smile/smilecdr/classes/client_certificates/kafka-client-cert.p12
module.clustermgr.config.kafka.ssl.keystore.password                =#{env['KAFKA_CLIENT_CERT_PWD']}
module.clustermgr.config.kafka.ssl.key.password                     =#{null}
    {{- else if eq $kafkaConfig.authentication.type "iam" }}
module.clustermgr.config.kafka.ssl.keystore.location                =#{null}
module.clustermgr.config.kafka.ssl.keystore.password                =#{null}
module.clustermgr.config.kafka.ssl.key.password                     =#{null}
    {{- end }}
  {{- else -}}
module.clustermgr.config.messagebroker.type                         =EMBEDDED_ACTIVEMQ
  {{- end }}
{{- end }}

{{/*
Define Smile CDR Node name
Currently only supports a single node. This was implemented
  so that we can remove the hard coded entry from the ConfigMap.
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
  {{- $nodeId := "" -}}
  {{- with .Values.cdrNodes -}}
    {{- $nodesMap := . -}}
    {{- /* If 2 or more entries, remove masterdev from map */ -}}
    {{- if gt (len $nodesMap) 1 -}}
      {{- $nodesMap = omit $nodesMap "masterdev" -}}
    {{- end -}}
    {{- range $key, $val := $nodesMap -}}
      {{- $nodeId = default $key $val.name -}}
    {{- end -}}
  {{- end -}}
  {{- $nodeId -}}
{{- end -}}

{{- /*
Temporary companion to "smilecdr.nodeId" until the multi-node feature is implemented.
This is just to get per-node settings, such as logs dir size.
*/ -}}
{{- define "smilecdr.nodeSettings" -}}
  {{- $nodeSettings := "" -}}
  {{- with .Values.cdrNodes -}}
    {{- $nodesMap := . -}}
    {{- if gt (len $nodesMap) 1 -}}
      {{- $nodesMap = omit $nodesMap "masterdev" -}}
    {{- end -}}
    {{- range $key, $val := $nodesMap -}}
      {{- $nodeSettings = deepCopy $val -}}
    {{- end -}}
  {{- end -}}
  {{- $nodeSettings | toYaml -}}
{{- end -}}
