{{/*
Define any file copies required by observability agents
*/}}
{{ define "observability.customerlib.sources" }}

  {{- $customerlibFileSources := list -}}

  {{- /* Add OpenTelemetry Logback appender Jar, only if enabled */ -}}
  {{- $otelAgentConfig := (include "observability.otelagent" . | fromYaml ) -}}
  {{- if and $otelAgentConfig.enabled false -}}
    {{- /* The enablement, filename and URL can be overriden if required.
          Set `disableAutoJarCopy` to true to disable copying this file. This will break
          IAM auth unless you add the file using `copyFIles`.
          This is an undocumented feature - if different files need to be added,
          the user should use the existing `copyFiles` feature instead. This override
          should only be used if troubleshooting this feature. */ -}}

    {{- if not $otelAgentConfig.disableAutoJarCopy -}}
      {{- $fileName := default "opentelemetry-logback-appender-1.0.jar" $otelAgentConfig.agentJarName -}}
      {{- $url := default "https://repo1.maven.org/maven2/io/opentelemetry/instrumentation/opentelemetry-logback-appender-1.0/1.26.0-alpha/opentelemetry-logback-appender-1.0-1.26.0-alpha.jar" $otelAgentConfig.agentJarUrl -}}
      {{- $OTAgentJarSource := dict "type" "curl" "url" $url "fileName" $fileName -}}
      {{- $customerlibFileSources = append $customerlibFileSources $OTAgentJarSource -}}
    {{- end -}}
  {{- end -}}

  {{- /* Add OpenTelemetry Logback appender dependency Jar, only if enabled */ -}}
  {{- if and $otelAgentConfig.enabled false -}}
    {{- /* The enablement, filename and URL can be overriden if required.
          Set `disableAutoJarCopy` to true to disable copying this file. This will break
          IAM auth unless you add the file using `copyFIles`.
          This is an undocumented feature - if different files need to be added,
          the user should use the existing `copyFiles` feature instead. This override
          should only be used if troubleshooting this feature. */ -}}
    {{- if not $otelAgentConfig.disableAutoJarCopy -}}
      {{- $fileName := default "opentelemetry-api-logs.jar" $otelAgentConfig.agentJarName -}}
      {{- $url := default "https://repo1.maven.org/maven2/io/opentelemetry/opentelemetry-api-logs/1.26.0-alpha/opentelemetry-api-logs-1.26.0-alpha.jar" $otelAgentConfig.agentJarUrl -}}
      {{- $OTAgentJarSource := dict "type" "curl" "url" $url "fileName" $fileName -}}
      {{- $customerlibFileSources = append $customerlibFileSources $OTAgentJarSource -}}
    {{- end -}}
  {{- end -}}
  {{- $customerlibFileSources | toYaml  -}}
{{- end -}}

{{/*
Define any file copies required by observability agents
*/}}
{{ define "observability.javaagent.sources" }}

  {{- $javaAgentSources := list -}}

  {{- /* Add OpenTelemetry Java Agent Jar, only if enabled and mode is set to 'helm' */ -}}
  {{- $otelAgentConfig := (include "observability.otelagent" . | fromYaml ) -}}
  {{- if and $otelAgentConfig.enabled (eq $otelAgentConfig.mode "helm") -}}
    {{- /* The enablement, filename and URL can be overriden if required.
          Set `disableAutoJarCopy` to true to disable copying this file. This will break
          IAM auth unless you add the file using `copyFIles`.
          This is an undocumented feature - if different files need to be added,
          the user should use the existing `copyFiles` feature instead. This override
          should only be used if troubleshooting this feature. */ -}}
    {{- if not $otelAgentConfig.disableAutoJarCopy -}}
      {{- $copyMethod := default "curl" $otelAgentConfig.copyMethod -}}
      {{- $fileName := default "opentelemetry-javaagent.jar" $otelAgentConfig.agentJarName -}}
      {{- $OTAgentJarSource := dict "type" $copyMethod "fileName" $fileName -}}
      {{- if eq $copyMethod "curl" -}}
        {{- $otelVersion := default "latest" $otelAgentConfig.agentVersion -}}
        {{- $url := default (printf "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/%s/download/opentelemetry-javaagent.jar" $otelVersion) $otelAgentConfig.agentJarUrl -}}
        {{- $_ := set $OTAgentJarSource "url" $url -}}
      {{- else if eq $copyMethod "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy java agent files from." $otelAgentConfig.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy java agent files from." $otelAgentConfig.path -}}
        {{- $_ := set $OTAgentJarSource "url" (printf "s3://%s%s" $bucket $bucketPath) -}}
      {{- end -}}
      {{- $javaAgentSources = append $javaAgentSources $OTAgentJarSource -}}
    {{- end -}}
  {{- end -}}

  {{- /* Add Prometheus JMX Java Agent Jar, if enabled */ -}}
  {{- $promAgentConfig := (include "observability.promagent" . | fromYaml ) -}}
  {{- if $promAgentConfig.enabled -}}
    {{- /* The enablement, filename and URL can be overriden if required.
          Set `disableAutoJarCopy` to true to disable copying this file. This will break
          IAM auth unless you add the file using `copyFIles`.
          This is an undocumented feature - if different files need to be added,
          the user should use the existing `copyFiles` feature instead. This override
          should only be used if troubleshooting this feature. */ -}}
    {{- if not $promAgentConfig.disableAutoJarCopy -}}
      {{- $fileName := default "jmx_prometheus_javaagent-0.17.2.jar" $promAgentConfig.agentJarName -}}
      {{- $url := default "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar" $promAgentConfig.agentJarUrl -}}
      {{- $promAgentJarSource := dict "type" "curl" "url" $url "fileName" $fileName -}}
      {{- $javaAgentSources = append $javaAgentSources $promAgentJarSource -}}
    {{- end -}}
  {{- end -}}
  {{- $javaAgentSources | toYaml  -}}
{{- end -}}

{{- /*
Define JMX config file contents.
*/ -}}
{{- define "observability.prometheus.agent.config.text" -}}
  {{- $jmxConfigText := "# JMX config file for prometheus java Agent auto generated from Helm Chart. Do not edit manually!\n" -}}
  {{- $jmxConfig := default (dict "rules" (list (dict "pattern" ".*"))) (.Values.observability.instrumentation.prometheus.promAgent).config -}}
  {{- $jmxConfigText = printf "%s\n%s" $jmxConfigText (toYaml $jmxConfig) -}}
  {{- $jmxConfigText -}}
{{- end -}}

{{- /*
Define observability related volumes requird by Smile CDR pod when observability is enabled.
*/ -}}
{{- define "observability.volumes" -}}
  {{- $volumes := list -}}
  {{- /* Add shared volumes for java agent files if enabled */ -}}
  {{- if (ne (len (include "observability.javaagent.sources" . | fromYamlArray)) 0) -}}
    {{- $volume := dict "name" "scdr-volume-javaagent" -}}
    {{- $_ := set $volume "emptyDir" (dict "sizeLimit" "100Mi") -}}
    {{- $volumes = append $volumes $volume -}}
  {{- end -}}

  {{- if (include "observability.promagent" . | fromYaml ).enabled -}}
    {{- /* Mount client jmx config file */ -}}
    {{- $configText := include "observability.prometheus.agent.config.text" . -}}
    {{- $cmName := printf "%s-scdr-prom-agent-config-%s-node%s" .Release.Name (.Values.nodeId | lower) (include "smilecdr.getConfigMapNameHashSuffix" (dict "Values" .Values "data" (printf "%s" $configText))) -}}
    {{- $configMap := (dict "name" $cmName) -}}
    {{- $propsVolume := dict "name" "jmx-config" "configMap" $configMap -}}
    {{- $volumes = append $volumes $propsVolume -}}
  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- /*
Define observability related volume mounts requird by Smile CDR when observability is enabled.
*/ -}}
{{- define "observability.volumeMounts" -}}
  {{- $volumeMounts := list -}}
  {{- /* Add shared volume for Java agent if enabled */ -}}
  {{- if (ne (len (include "observability.javaagent.sources" . | fromYamlArray)) 0) -}}
    {{- $volumeMount := dict "name" "scdr-volume-javaagent" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/javaagent" -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}

  {{- if (include "observability.promagent" . | fromYaml ).enabled -}}
    {{- /* Mount client jmx config file */ -}}
    {{- $volumeMount := dict "name" "jmx-config" -}}
    {{- $_ := set $volumeMount "mountPath" "/home/smile/smilecdr/customerlib/jmxconf.yaml" -}}
    {{- $_ := set $volumeMount "subPath" "jmxconf.yaml" -}}
    {{- /* $_ := set $volumeMount "readOnly" true */ -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}

{{/*
Define Observability annotations
These are annotations used by various observability operators such as OpenTelemetry and Jaeger
Note that some operators look for the annotations on the Deployment and some look for it on the pod.
*/}}

{{- define "observability.annotations.deployment" -}}
  {{- $annotations := dict -}}
  {{- if (.Values.observability.instrumentation.jaeger).enabled -}}
    {{- $_ := set $annotations "sidecar.jaegertracing.io/inject" (printf "%s-scdr-otelcoll" .Release.Name) -}}
  {{- end -}}
  {{- $annotations | toYaml -}}
{{- end -}}

{{- define "observability.annotations.pod" -}}
  {{- $annotations := dict -}}
  {{- /* Include Pod annotations for Java agent when using OpenTelemetry operator/crd */ -}}
  {{- $otelAgentConfig := (include "observability.otelagent" . | fromYaml) -}}
  {{- if $otelAgentConfig.crdEnabled -}}
    {{- $_ := set $annotations "instrumentation.opentelemetry.io/inject-java" true -}}
    {{- $_ := set $annotations "instrumentation.opentelemetry.io/container-names" .Chart.Name -}}
  {{- end -}}
  {{- /* Include Pod annotations for Otel Collector sidecar container when using OpenTelemetry operator/crd */ -}}
  {{- $otelCollConfig := (include "observability.otelcoll" . | fromYaml) -}}
  {{- if and $otelCollConfig.crdEnabled (eq $otelCollConfig.mode "sidecar") -}}
    {{- $_ := set $annotations "sidecar.opentelemetry.io/inject" (printf "%s-scdr-otelcoll" .Release.Name) -}}
  {{- end -}}
  {{- $annotations | toYaml -}}
{{- end -}}

{{- define "observability.createSafeEnvVar" -}}
  {{- $theCustomList := index . 0 -}}
  {{- $theEnvVarName := index . 1 -}}
  {{- $theEnvVarValue := index . 2 -}}
  {{- $theCreatedEnvVar := dict "name" $theEnvVarName -}}
  {{- /* if eq $theEnvVarName "OTEL_RESOURCE_ATTRIBUTES_POD_NAME" -}}
    {{- if kindIs "map" $theEnvVarValue -}}
      {{- fail "gotit!" -}}
    {{- else -}}
      {{- fail (kindOf $theEnvVarValue) -}}
    {{- end -}}
  {{- end */ -}}
  {{- if kindIs "map" $theEnvVarValue -}}
    {{ if not (hasKey $theEnvVarValue "valueFrom") }}
      {{- fail "Something is wrong... " -}}
    {{- end -}}
    {{- $_ := set $theCreatedEnvVar "valueFrom" $theEnvVarValue.valueFrom -}}
  {{- else -}}
    {{- $_ := set $theCreatedEnvVar "value" $theEnvVarValue -}}
  {{- end -}}
  {{- range $listItem := $theCustomList -}}
    {{- if and (hasKey $listItem "name") (eq $listItem.name $theEnvVarName) -}}
      {{- if $listItem.override -}}
        {{- /* The overridden variable has already been included, so do not add it. */ -}}
        {{- $theCreatedEnvVar = false -}}
      {{- else -}}
        {{- fail (printf "You have defined the Otel Java agent variable: `%s`, but it should be auto-generated by the Helm Chart.\nIf you need to manually override this variable, you can provide `override: true` in your env var definition." $theEnvVarName) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if $theCreatedEnvVar -}}
    {{- $theCreatedEnvVar | toYaml -}}
  {{- end -}}
{{- end -}}

{{- /*
Define env vars that will be used for observability
*/ -}}
{{- define "observability.envVars" -}}
  {{- $envVars := list -}}
  {{- /* Add Otel Java Agent Jar, only if enabled via Helm */ -}}
  {{- $otelAgentConfig := (include "observability.otelagent" . | fromYaml ) -}}
  {{- if and $otelAgentConfig.enabled (eq $otelAgentConfig.mode "helm") -}}
    {{- /* JAVA Agent configuration */ -}}
    {{- $fileName := default "opentelemetry-javaagent.jar" $otelAgentConfig.agentJarName -}}
    {{- $dirName := "/home/smile/smilecdr/javaagent" -}}
    {{- $env := dict "name" "JAVA_TOOL_OPTIONS" "value" (printf "-javaagent:%s/%s"  $dirName $fileName) -}}
    {{- $envVars = append $envVars $env -}}
    {{- /* Configure the Otel Java agent based on any provided `spec`. */ -}}
    {{- $customEnvVars := list -}}
    {{- if hasKey $otelAgentConfig "spec" -}}
      {{- $theAgentSpec := $otelAgentConfig.spec -}}

      {{- /* First create any env vars that should be configured based on the provided `spec`. */ -}}

      {{- /* OTEL Exporter Endpoint
          https://github.com/open-telemetry/opentelemetry-operator/blob/main/docs/api.md#instrumentationspecexporter
           */ -}}
      {{- if and (hasKey $theAgentSpec "exporter") (hasKey $theAgentSpec.exporter "endpoint") -}}
        {{- $env := dict "name" "OTEL_EXPORTER_OTLP_ENDPOINT" "value" $theAgentSpec.exporter.endpoint -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}

      {{- /* OTEL Propagators
          https://github.com/open-telemetry/opentelemetry-operator/blob/main/docs/api.md#instrumentationspec
           */ -}}
      {{- if and (hasKey $theAgentSpec "propagators") -}}
        {{- $propagatorsString := join "," $theAgentSpec.propagators -}}
        {{- $env := dict "name" "OTEL_PROPAGATORS" "value" $propagatorsString -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}

      {{- /* OTEL Sampler configurations
          https://github.com/open-telemetry/opentelemetry-operator/blob/main/docs/api.md#instrumentationspecsampler
           */ -}}
      {{- if hasKey $theAgentSpec "sampler" -}}
        {{- if hasKey $theAgentSpec.sampler "type" -}}
          {{- $env := dict "name" "OTEL_TRACES_SAMPLER" "value" $theAgentSpec.sampler.type -}}
          {{- $envVars = append $envVars $env -}}
        {{- end -}}
        {{- if hasKey $theAgentSpec.sampler "argument" -}}
          {{- $env := dict "name" "OTEL_TRACES_SAMPLER_ARG" "value" $theAgentSpec.sampler.argument -}}
          {{- $envVars = append $envVars $env -}}
        {{- end -}}
      {{- end -}}

      {{- /* Create any required env vars for resource attributes */ -}}
      {{- $resourceAttributes := list -}}
      {{- $serviceNameDefined := false -}}
      {{- range $theAttributeSpec := $theAgentSpec.resourceAttributes -}}
        {{- $attrName := required "You must provide a `name` when configuring resource attributes for the Open Telemetry agent." $theAttributeSpec.name -}}
        {{- $varName := printf "OTEL_RESOURCE_ATTRIBUTES_%s" (upper (replace "." "_" $attrName)) -}}
        {{- if and (hasKey $theAttributeSpec "value") (hasKey $theAttributeSpec "valueFrom") -}}
          {{- fail (printf "Open Telemetry agent resource attribute `%s` must have `value` or `valueFrom` but not both." $attrName) -}}
        {{- else if hasKey $theAttributeSpec "valueFrom" -}}
          {{- /* Use DownwardAPI to get value from pod label */ -}}
          {{- if and (kindIs "map" $theAttributeSpec.valueFrom) (hasKey $theAttributeSpec.valueFrom "podLabel") -}}
            {{- $podLabel := $theAttributeSpec.valueFrom.podLabel -}}
            {{- $theValueFrom := dict "fieldRef" (dict "apiVersion" "v1" "fieldPath" (printf "metadata.labels['%s']" $podLabel)) -}}
            {{- $env = dict "name" $varName "valueFrom" $theValueFrom -}}
            {{- $envVars = append $envVars $env -}}
            {{- $resourceAttributes = append $resourceAttributes (printf "%s=$(%s)" $attrName $varName) -}}
          {{- else if has $theAttributeSpec.valueFrom (splitList " " "metadata.name metadata.namespace spec.nodeName") -}}
            {{- $theValueFrom := dict "fieldRef" (dict "apiVersion" "v1" "fieldPath" $theAttributeSpec.valueFrom) -}}
            {{- $env = dict "name" $varName "valueFrom" $theValueFrom -}}
            {{- $envVars = append $envVars $env -}}
            {{- $resourceAttributes = append $resourceAttributes (printf "%s=$(%s)" $attrName $varName) -}}
          {{- else if has $theAttributeSpec.valueFrom (splitList " " "deployment.name replicaset.name") -}}
            {{- /* We need an env var with deployment name for either of these. */ -}}
            {{- $env = dict "name" "OTEL_RESOURCE_ATTRIBUTES_K8S_DEPLOYMENT_NAME" "value" (printf "%s-%s" $.Release.Name $.Values.resourceSuffix) -}}
            {{- if not (has $env $envVars) -}}
              {{- $envVars = append $envVars $env -}}
            {{- end -}}
            {{- if eq $theAttributeSpec.valueFrom "deployment.name" -}}
              {{- $resourceAttributes = append $resourceAttributes (printf "%s=$(%s)" $attrName "OTEL_RESOURCE_ATTRIBUTES_K8S_DEPLOYMENT_NAME") -}}
            {{- else if eq $theAttributeSpec.valueFrom "replicaset.name" -}}
              {{- $theValueFrom := dict "fieldRef" (dict "apiVersion" "v1" "fieldPath" "metadata.labels['pod-template-hash']") -}}
              {{- $env = dict "name" "OTEL_RESOURCE_ATTRIBUTES_K8S_POD_TEMPLATE_HASH" "valueFrom" $theValueFrom -}}
              {{- $envVars = append $envVars $env -}}
              {{- $env = dict "name" "OTEL_RESOURCE_ATTRIBUTES_K8S_REPLICASET_NAME" "value" "$(OTEL_RESOURCE_ATTRIBUTES_K8S_DEPLOYMENT_NAME)-$(OTEL_RESOURCE_ATTRIBUTES_K8S_POD_TEMPLATE_HASH)" -}}
              {{- $envVars = append $envVars $env -}}
              {{- $resourceAttributes = append $resourceAttributes (printf "%s=$(%s)" $attrName "OTEL_RESOURCE_ATTRIBUTES_K8S_REPLICASET_NAME") -}}
            {{- end -}}
          {{- end -}}
        {{- else if hasKey $theAttributeSpec "value" -}}
          {{- $resourceAttributes = append $resourceAttributes (printf "%s=%s" $attrName $theAttributeSpec.value) -}}
        {{- end -}}
        {{- if eq $attrName "service.name" -}}
          {{- $serviceNameDefined = true -}}
        {{- end -}}
      {{- end -}}

      {{- /* Include any environment variables passed in directly via the configuration
          Only include them if they do not already exist. If they do exist then only include them
          if override is set */ -}}
      {{- /* Common env vars */ -}}
      {{- if hasKey $theAgentSpec "env" -}}
        {{- $customEnvVars = compact $theAgentSpec.env -}}
      {{- end -}}
      {{- /* Java instrumentation env vars */ -}}
      {{- if and (hasKey $theAgentSpec "java") (hasKey $theAgentSpec.java "env") -}}
        {{- $customEnvVars = uniq (concat $customEnvVars (compact $theAgentSpec.java.env)) -}}
      {{- end -}}
      {{- $resourceAttributesOverrideEnvVar := false -}}
      {{- range $theCustomEnvVar := $customEnvVars -}}
        {{- if hasKey $theCustomEnvVar "name" -}}
          {{- $fail := false -}}
          {{- if eq $theCustomEnvVar.name "OTEL_RESOURCE_ATTRIBUTES" -}}
            {{- if $theCustomEnvVar.override -}}
              {{- /* Overriding OTEL_RESOURCE_ATTRIBUTES is a special case that must be done after the autoconfiguration */ -}}
              {{- /* Save this variable for later, rather than having to parse the list again. */ -}}
              {{- $resourceAttributesOverrideEnvVar = deepCopy (omit $theCustomEnvVar "override") -}}
            {{- else -}}
              {{- $fail = true -}}
            {{- end -}}
          {{- else -}}
            {{- range $theExistingEnvVar := $envVars -}}
              {{- if eq $theCustomEnvVar.name $theExistingEnvVar.name -}}
                {{- if $theCustomEnvVar.override -}}
                  {{- /* This variable is being overriden, so remove original from the main list */ -}}
                  {{- $envVars = without $envVars $theExistingEnvVar -}}
                {{- else -}}
                  {{- $fail = true -}}
                {{- end -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
          {{- if (eq $theCustomEnvVar.name "OTEL_SERVICE_NAME") -}}
            {{- if $serviceNameDefined -}}
              {{- /* Service name is already defined in $resourceAttributes. Are we overriding it? */ -}}
              {{- if $theCustomEnvVar.override -}}
                {{- /* We need to remove the service.name from $resourceAttributes. Not essential right now though. */ -}}
              {{- else -}}
                {{- $fail = true -}}
              {{- end -}}
            {{- else -}}
              {{- $serviceNameDefined = true -}}
            {{- end -}}
          {{- end -}}
          {{- if $fail -}}
            {{- fail (printf "You have defined the Otel Java agent variable: `%s`, but it was auto-generated by the Helm Chart.\nIf you need to manually override this variable, you can provide `override: true` in your env var definition." $theCustomEnvVar.name) -}}
          {{- else -}}
            {{- $envVars = append $envVars (omit $theCustomEnvVar "override") -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- /* Define mandatory service name if not already done. */ -}}
      {{- if not $serviceNameDefined -}}
        {{- /* By default, this will be the same as the Deployment Name*/ -}}
        {{- $env = dict "name" "OTEL_SERVICE_NAME" "value" (printf "%s-%s" $.Release.Name $.Values.resourceSuffix) -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}

      {{- /* OTEL_RESOURCE_ATTRIBUTES needs to be the last env var defined in case it references any env vars provided elsewhere */ -}}
      {{- if $resourceAttributesOverrideEnvVar -}}
        {{- $envVars = append $envVars $resourceAttributesOverrideEnvVar -}}
      {{- else -}}
        {{- if gt (len $resourceAttributes) 0 -}}
          {{- $theValue := join "," $resourceAttributes -}}
          {{- $env = dict "name" "OTEL_RESOURCE_ATTRIBUTES" "value" $theValue -}}
          {{- $envVars = append $envVars $env -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Add Prometheus JMX Java Agent Jar, only if enabled */ -}}
  {{- $promAgentConfig := (include "observability.promagent" . | fromYaml ) -}}
  {{- if $promAgentConfig.enabled -}}
    {{- $fileName := default "jmx_prometheus_javaagent-0.17.2.jar" (.Values.observability.instrumentation.prometheus.jvmMetrics).agentJarName -}}
    {{- $agentPort := default "17171" (.Values.observability.instrumentation.prometheus.jvmMetrics).agentPort -}}
    {{- $dirName := "/home/smile/smilecdr/javaagent" -}}
    {{- $env := dict "name" "JAVA_TOOL_OPTIONS" -}}
    {{- $_ := set $env "value" (printf "-javaagent:%s/%s=%s:%s/jmxconf.yaml" $dirName $fileName $agentPort $dirName) -}}
    {{- $envVars = append $envVars $env -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}


{{/*
Some helpers to reduce verbosity of if statements elsewhere.
*/}}

{{- define "observability.otelagent" -}}
  {{- $otelAgentConfig := dict -}}
  {{- if and .Values.observability.enabled (.Values.observability.instrumentation).openTelemetry.enabled ((.Values.observability.instrumentation.openTelemetry).otelAgent).enabled -}}
    {{- $otelAgentConfig = deepCopy .Values.observability.instrumentation.openTelemetry.otelAgent -}}
    {{- if eq .Values.observability.instrumentation.openTelemetry.otelAgent.mode "operator" -}}
      {{- $_ := set $otelAgentConfig "crdEnabled" true -}}
    {{- else -}}
      {{- $_ := set $otelAgentConfig "crdEnabled" false -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set $otelAgentConfig "enabled" false -}}
    {{- $_ := set $otelAgentConfig "crdEnabled" false -}}
  {{- end -}}
  {{- $otelAgentConfig | toYaml -}}
{{- end -}}

{{- define "observability.otelcoll" -}}
  {{- $otelCollConfig := dict -}}
  {{- if and .Values.observability.enabled (.Values.observability.instrumentation).openTelemetry.enabled ((.Values.observability.instrumentation.openTelemetry).otelCollector).enabled -}}
    {{- $otelCollConfig = deepCopy .Values.observability.instrumentation.openTelemetry.otelCollector -}}
    {{- if eq .Values.observability.instrumentation.openTelemetry.otelCollector.mode "sidecar" -}}
      {{- $_ := set $otelCollConfig "crdEnabled" true -}}
    {{- else -}}
      {{- $_ := set $otelCollConfig "crdEnabled" false -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set $otelCollConfig "enabled" false -}}
    {{- $_ := set $otelCollConfig "crdEnabled" false -}}
  {{- end -}}
  {{- $otelCollConfig | toYaml -}}
{{- end -}}

{{- define "observability.promagent" -}}
  {{- $promAgentConfig := dict -}}
  {{- if and .Values.observability.enabled .Values.observability.instrumentation.prometheus.enabled .Values.observability.instrumentation.prometheus.promAgent.enabled -}}
    {{- $promAgentConfig = deepCopy .Values.observability.instrumentation.prometheus.promAgent -}}
  {{- else -}}
    {{- $_ := set $promAgentConfig "enabled" false -}}
  {{- end -}}
  {{- $promAgentConfig | toYaml -}}
{{- end -}}
