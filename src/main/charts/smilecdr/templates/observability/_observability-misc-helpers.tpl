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
          OTEL Logback Appender functionality unless you add the file using `copyFiles`.
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
          OTEL Logback Appender functionality unless you add the file using `copyFiles`.
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
          OTEL Java Agent functionality unless you add the file using `copyFiles`.
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
          Prometheus Java Agent functionality unless you add the file using `copyFiles`.
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
    {{- $cmName := printf "%s-scdr-prom-agent-config-%s-node%s" .Release.Name (.Values.cdrNodeId | lower) (include "smilecdr.getConfigMapNameHashSuffix" (dict "Values" .Values "data" (printf "%s" $configText))) -}}
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
  {{- if $otelAgentConfig.useOperator -}}
    {{- $_ := set $annotations "instrumentation.opentelemetry.io/inject-java" true -}}
    {{- $_ := set $annotations "instrumentation.opentelemetry.io/container-names" .Chart.Name -}}
  {{- end -}}
  {{- /* Include Pod annotations for Otel Collector sidecar container when using OpenTelemetry operator/crd */ -}}
  {{- $otelCollConfig := (include "observability.otelcoll" . | fromYaml) -}}
  {{- if and $otelCollConfig.useOperator (eq $otelCollConfig.mode "sidecar") -}}
    {{- $_ := set $annotations "sidecar.opentelemetry.io/inject" (printf "%s-scdr-otelcoll" .Release.Name) -}}
  {{- end -}}
  {{- $annotations | toYaml -}}
{{- end -}}

{{- define "observability.createSafeEnvVar" -}}
  {{- $theCustomList := index . 0 -}}
  {{- $theEnvVarName := index . 1 -}}
  {{- $theEnvVarValue := index . 2 -}}
  {{- $theCreatedEnvVar := dict "name" $theEnvVarName -}}
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
        {{- fail (printf "1-You have defined the Otel Java agent variable: `%s`, but it should be auto-generated by the Helm Chart.\nIf you need to manually override this variable, you can provide `override: true` in your env var definition." $theEnvVarName) -}}
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
  {{- /* Add Otel Java Agent Jar Env Vars, only if enabled via Helm */ -}}
  {{- $otelAgentConfig := (include "observability.otelagent" . | fromYaml ) -}}
  {{- if and $otelAgentConfig.enabled (eq $otelAgentConfig.mode "helm") -}}
    {{- /* JAVA Agent configuration */ -}}
    {{- $fileName := default "opentelemetry-javaagent.jar" $otelAgentConfig.agentJarName -}}
    {{- $dirName := "/home/smile/smilecdr/javaagent" -}}
    {{- $env := dict "name" "JAVA_TOOL_OPTIONS" "value" (printf "-javaagent:%s/%s"  $dirName $fileName) -}}
    {{- $envVars = append $envVars $env -}}
    {{- /* Configure the Otel Java agent based on any provided `spec`. */ -}}
    {{- /* $customEnvVars := list */ -}}
    {{- $customEnvVars := dict -}}

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

      {{- /* Create any required env vars for resource attributes
          For each resource attribute, there is an env var as well as a reference to the env var in the
          `OTEL_RESOURCE_ATTRIBUTES` env var. This mirrors the behaviour of the OTEL Agent operator. */ -}}

      {{- /* The `$resourceAttributes` list is ultimately rendered into the env var as follows:
          `name: OTEL_RESOURCE_ATTRIBUTES`
          `value: k8s.deployment.name=$(OTEL_RESOURCE_ATTRIBUTES_K8S_DEPLOYMENT_NAME),k8s.node.name=$(OTEL_RESOURCE_ATTRIBUTES_K8S_NODE_NAME)`
          etc.. */ -}}
      {{- $resourceAttributes := list -}}
      {{- $serviceNameDefined := false -}}
      {{- range $theAttributeSpec := $theAgentSpec.resourceAttributes -}}
      {{- /* range $theAttributeName, $theAttributeSpec := $theAgentSpec.resourceAttributes */ -}}
        {{- /* TODO: Can this check be moved to `observability.otelagent` where it's turned from list to dict? */ -}}
        {{- $attrName := required "You must provide a `name` when configuring resource attributes for the Open Telemetry agent." $theAttributeSpec.name -}}
        {{- /* if ne $ß $attrName -}}
          {{- fail (printf "\nInvestigate $theAttributeName ne $attrName\n$theAttributeName: %s\n $attrName: %s\n\n" $theAttributeName $attrName) -}}
        {{- end */ -}}
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
          Only include them if they do not already exist. If they do already exist then only include them
          if override is set */ -}}

      {{- /* Combined env vars */ -}}
      {{- if hasKey $otelAgentConfig "allEnvVars" -}}
        {{- $customEnvVars = $otelAgentConfig.allEnvVars -}}
      {{- else -}}

        {{- /* Common env vars */ -}}
        {{- if hasKey $theAgentSpec "env" -}}
          {{- $customEnvVars = deepCopy $theAgentSpec.env -}}
        {{- end -}}

        {{- if and (hasKey $theAgentSpec "java") (hasKey $theAgentSpec.java "env") -}}
          {{- /* Java instrumentation env vars */ -}}

          {{- /* This does not work. Concatenating a list can result with duplicates,
              as the dicts can be different even when they have the same 'name'. Lists
              of dicts are simply not a good data structure for internal representation... */ -}}
          {{- /* $customEnvVars = uniq (concat $customEnvVars (compact $theAgentSpec.java.env)) */ -}}

          {{- /* This here is why the theAgentSpec 'env' sections need to be represented as a list,
              so that we can do this merge. */ -}}
          {{- $customEnvVars = deepCopy (mergeOverwrite $customEnvVars $theAgentSpec.java.env) -}}
          {{- /* fail (printf "\n$customEnvVars: \n\n%s\n" (toPrettyJson $customEnvVars)) */ -}}
        {{- end -}}

      {{- end -}}

      {{- /* fail (printf "$customEnvVars: \n\n%s\n" (toPrettyJson $customEnvVars)) -}}
      {{- fail (printf "Existing env vars:\n%s\n\n" (toPrettyJson $envVars)) */ -}}

      {{- $resourceAttributesOverrideEnvVar := false -}}
      {{- range $theCustomEnvVarName, $theCustomEnvVar := $customEnvVars -}}
        {{- /* if hasKey $theCustomEnvVar "name" */ -}}
          {{- $_ := set $theCustomEnvVar "name" (default $theCustomEnvVarName $theCustomEnvVar.name) -}}
          {{- /* if not (hasKey $theCustomEnvVar "name") -}}
            {{- fail (printf "Existing env vars:\n%s\n\n$theCustomEnvVar:\n%s\n$theCustomEnvVar.name: %s\n\n" (toPrettyJson $envVars) (toPrettyJson $theCustomEnvVar) $theCustomEnvVar.name) -}}
          {{- end */ -}}
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
            {{- /* For all other env vars, only set them if they don't already exist */ -}}
            {{- range $theExistingEnvVar := $envVars -}}
              {{- if eq $theCustomEnvVar.name $theExistingEnvVar.name -}}
                {{- if $theCustomEnvVar.override -}}
                  {{- /* This variable is being overriden, so remove original from the main list */ -}}
                  {{- $envVars = without $envVars $theExistingEnvVar -}}
                {{- else -}}
                  {{- $fail = true -}}
                  {{- fail (printf "Existing env vars:\n%s\n\n$theCustomEnvVar:\n%s\n\n" (toPrettyJson $envVars) (toPrettyJson $theCustomEnvVar)) -}}
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
            {{- fail (printf "2-You have defined the Otel Java agent variable: `%s`, but it was auto-generated by the Helm Chart.\nIf you need to manually override this variable, you can provide `override: true` in your env var definition." $theCustomEnvVar.name) -}}
          {{- else -}}
            {{- $envVars = append $envVars (omit $theCustomEnvVar "override") -}}
          {{- end -}}
        {{- /* end */ -}}
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

  {{- /* Add Prometheus JMX Java Agent Jar ENV Vars, only if enabled */ -}}
  {{- $promAgentConfig := (include "observability.promagent" . | fromYaml ) -}}
  {{- if $promAgentConfig.enabled -}}
    {{- $fileName := default "jmx_prometheus_javaagent-0.17.2.jar" $promAgentConfig.agentJarName -}}
    {{- $agentPort := default "17171" $promAgentConfig.config.port -}}
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

{{- define "observability.lokideployment.enabled" -}}
  {{- if .Values.observability.enabled -}}
    {{- if or (and ((.Values.observability.services).logging).enabled .Values.observability.services.logging.loki.enabled) (and ((.Values.observability.services).tracing).enabled (.Values.observability.services.tracing.loki).enabled) -}}
      {{- true -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "observability.lokideployment.config" -}}
  {{- $lokiConf := dict -}}
  {{- if .Values.observability.enabled -}}
    {{- if or (and ((.Values.observability.services).logging).enabled .Values.observability.services.logging.loki.enabled) (and ((.Values.observability.services).tracing).enabled (.Values.observability.services.tracing.loki).enabled) -}}
      {{- $_ := set $lokiConf "enabled" "true" -}}
      {{- $saConfig := dict -}}
      {{- $_ := set $saConfig "name" (default (printf "%s-%s" (include "smilecdr.fullname" .) "loki" ) (.Values.observability.services.logging.loki.serviceAccount).name) -}}
      {{- /* if (.Values.observability.services.logging.loki.serviceAccount).name -}}
        {{- $_ := set $saConfig "name"  -}}
      {{- else -}}
        {{- $_ := set $saConfig "name"  -}}
      {{- end */ -}}
      {{- $_ := set $saConfig "create" (default "true" ((.Values.observability.services.logging.loki.serviceAccount).create )) -}}
      {{- /*if (.Values.observability.services.logging.loki.serviceAccount).create }}
        {{- $_ := set $saConfig "create" true -}}
      {{- else -}}
        {{- $_ := set $lokiConf "create" false -}}
      {{- end */ -}}
      {{- $_ := set $saConfig "annotations" (default dict (.Values.observability.services.logging.loki.serviceAccount).annotations) -}}
      {{- $_ := set $lokiConf "serviceAccount" $saConfig -}}
      {{- $_ := set $lokiConf "bucketNames" .Values.observability.services.logging.loki.bucketNames -}}
      {{- /* fail (printf "Loki bucket names: %s" (toPrettyJson .Values.observability.services.logging.loki)) */ -}}

    {{- end -}}
  {{- end -}}
  {{- $lokiConf | toYaml -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "observability.lokideployment.serviceAccountName" -}}
{{- if .Values.observability.services.logging.loki.serviceAccount.create }}
{{- default (include "observability.lokideployment.fullname" .) .Values.observability.services.logging.loki.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.observability.services.logging.loki.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "observability.lokideployment.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "observability.otelagent" -}}
  {{- /* Set defaults */ -}}
  {{- $otelAgentConfig := dict "enabled" false "useOperator" false -}}
  {{- if and .Values.observability.enabled (.Values.observability.instrumentation).openTelemetry.enabled ((.Values.observability.instrumentation.openTelemetry).otelAgent).enabled -}}
    {{- $otelAgentConfig = deepCopy .Values.observability.instrumentation.openTelemetry.otelAgent -}}
    {{- if eq .Values.observability.instrumentation.openTelemetry.otelAgent.mode "operator" -}}
      {{- $_ := set $otelAgentConfig "useOperator" true -}}
    {{- end -}}

    {{- /* Set the exporters based on provided `env:`
        Note that we cannot set any defaults in the values file
        with `observability...env` as you cannot merge lists in Helm.
        Instead we must programatically set the defaults here.

        Ideally, we should change the spec to use dicts instead of lists to avoid
        this issue. But it's already in use. This may be hard to deprecate.

        Not only that, but the OTEL operator already uses lists in its CRD. It makes
        sense to use the same schema.

        Solution is to provide `specOverrides` - a dict that can be used to modify the spoec
        */ -}}

    {{- $exporters := dict -}}
    {{- /* Set the defaults */ -}}

    {{- /* Before doing any merging, copy 'spec' items and convert elements of type list to dict */ -}}
    {{- $specDict := deepCopy $otelAgentConfig.spec -}}
    {{- /* fail (printf "\n$specDict:\n%s\n\n$otelAgentConfig.spec:\n%s\n" (toPrettyJson $specDict) (toPrettyJson $otelAgentConfig.spec) ) */ -}}

    {{- /* Convert `spec.resourceAttributes' list to dict */ -}}
    {{- if hasKey $specDict "resourceAttributes" -}}
      {{- $oldList := deepCopy $specDict.resourceAttributes -}}
      {{- $_ := set $specDict "resourceAttributes" dict -}}
      {{- range $theResourceAttribute := $oldList -}}
        {{- $_ := set $specDict.resourceAttributes $theResourceAttribute.name $theResourceAttribute -}}
      {{- end -}}
    {{- end -}}

    {{- /* Convert `spec.env' list to dict */ -}}
    {{- if hasKey $specDict "env" -}}
      {{- $oldList := deepCopy $specDict.env -}}
      {{- $_ := set $specDict "env" dict -}}
      {{- range $theEnvVar := $oldList -}}
        {{- $_ := set $specDict.env $theEnvVar.name $theEnvVar -}}
      {{- end -}}
    {{- end -}}


    {{- /* Convert `spec.java.env' list to dict */ -}}
    {{- if hasKey $specDict.java "env" -}}
      {{- $oldList := deepCopy $specDict.java.env -}}
      {{- $_ := set $specDict.java "env" dict -}}
      {{- range $theJavaEnvVar := $oldList -}}
        {{- $_ := set $specDict.java.env $theJavaEnvVar.name $theJavaEnvVar -}}
      {{- end -}}
      {{- /* fail (printf "\n$specDict:\n%s\n\n$oldList:\n\n%s\n" (toPrettyJson $specDict) (toPrettyJson $oldList) ) */ -}}
    {{- end -}}


    {{- /* Now we can set defaults */ -}}
    {{- $otelAgentDefaultSpec := dict "env" dict -}}
    {{- $_ := set $otelAgentDefaultSpec.env "OTEL_METRICS_EXPORTER" (dict "value" "none") -}}
    {{- $_ := set $otelAgentDefaultSpec.env "OTEL_LOGS_EXPORTER" (dict "value" "none") -}}
    {{- $_ := set $otelAgentDefaultSpec.env "OTEL_TRACES_EXPORTER" (dict "value" "none") -}}

    {{- /* Java defaults */ -}}
    {{- $_ := set $otelAgentDefaultSpec "java" (dict "env" dict) -}}
    {{- $_ := set $otelAgentDefaultSpec.java.env "OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_LOG_ATTRIBUTES" (dict "value" "true") -}}
    {{- $_ := set $otelAgentDefaultSpec.java.env "OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_MARKER_ATTRIBUTE" (dict "value" "true") -}}
    {{- $_ := set $otelAgentDefaultSpec.java.env "OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_CODE_ATTRIBUTES" (dict "value" "true") -}}
    {{- $_ := set $otelAgentDefaultSpec.java.env "OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_KEY_VALUE_PAIR_ATTRIBUTES" (dict "value" "true") -}}
    {{- $_ := set $otelAgentDefaultSpec.java.env "OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_LOGGER_CONTEXT_ATTRIBUTES" (dict "value" "true") -}}

    {{- $origSpec := deepCopy $otelAgentConfig.spec -}}
    {{- $newSpec := deepCopy (mergeOverwrite (default dict $otelAgentConfig.specOverrides) $otelAgentDefaultSpec $specDict) -}}
    {{- /* $newSpec := deepCopy (merge (default dict $otelAgentConfig.specOverrides) $otelAgentDefaultSpec $specDict) */ -}}
    {{- /* fail (printf "\n$specDict:\n%s\n\n$newSpec:\n\n%s\n" (toPrettyJson $specDict) (toPrettyJson $newSpec) ) */ -}}
    {{- /*if hasKey $otelAgentConfig "specOverrides" -}}
      {{- $_ := set $otelAgentConfig "spec" (deepCopy (merge $otelAgentConfig.specOverrides $specDict $otelAgentDefaultSpec)) -}}
    {{- end */ -}}

    {{- $_ := set $otelAgentConfig "allEnvVars" (mergeOverwrite $newSpec.env $newSpec.java.env ) -}}

    {{- /* Convert `spec.resourceAttributes' dict to list */ -}}
    {{- if hasKey $newSpec "resourceAttributes" -}}
      {{- $resourceAttributesList := list -}}
      {{- range $theResourceAttributeKey, $theResourceAttribute := $newSpec.resourceAttributes -}}
        {{- $theListItem := merge (dict "name" $theResourceAttributeKey) $theResourceAttribute -}}
        {{- $resourceAttributesList = append $resourceAttributesList $theListItem -}}
      {{- end -}}
      {{- $_ := set $otelAgentConfig.spec "resourceAttributes" $resourceAttributesList -}}
    {{- end -}}


    {{- /* if hasKey $newSpec "resourceAttributes" -}}
      {{- $_ := set $otelAgentConfig.spec "resourceAttributes" $newSpec.resourceAttributes -}}
    {{- end */ -}}

    {{- /* Convert `spec.env' dict to list */ -}}
    {{- if hasKey $newSpec "env" -}}
      {{- $envVarsList := list -}}
      {{- range $theEnvVarKey, $theEnvVarValue := $newSpec.env -}}
        {{- $theListItem := merge (dict "name" $theEnvVarKey) $theEnvVarValue -}}
        {{- $envVarsList = append $envVarsList $theListItem -}}
      {{- end -}}
      {{- $_ := set $otelAgentConfig.spec "env" $envVarsList -}}
    {{- end -}}

    {{- /* if hasKey $newSpec "env" -}}
      {{- $_ := set $otelAgentConfig.spec "env" $newSpec.env -}}
    {{- end */ -}}

    {{- /* Convert `spec.java.env' dict to list */ -}}
    {{- if hasKey $newSpec.java "env" -}}
      {{- $javaEnvVarsList := list -}}
      {{- range $theJavaEnvVarKey, $theJavaEnvVarValue := $newSpec.java.env -}}
        {{- $theListItem := merge (dict "name" $theJavaEnvVarKey) $theJavaEnvVarValue -}}
        {{- $javaEnvVarsList = append $javaEnvVarsList $theListItem -}}
      {{- end -}}
      {{- $_ := set $otelAgentConfig.spec.java "env" $javaEnvVarsList -}}
    {{- end -}}

    {{- /* if hasKey $newSpec.java "env" -}}
      {{- $_ := set $otelAgentConfig.spec.java "env" $newSpec.java.env -}}
    {{- end */ -}}

    {{- /* fail (printf "OLD:\n%s\n\nNEW:\n%s\n\n" (toPrettyJson $origSpec) (toPrettyJson $otelAgentConfig.spec)) */ -}}

  {{- end -}}
  {{- $otelAgentConfig | toYaml -}}
{{- end -}}

{{- define "observability.otelcoll" -}}
  {{- /* Set defaults */ -}}
  {{- $otelCollConfig := dict "enabled" false "useOperator" false -}}

  {{- if and .Values.observability.enabled (.Values.observability.instrumentation).openTelemetry.enabled ((.Values.observability.instrumentation.openTelemetry).otelCollector).enabled -}}
    {{- $otelCollConfig = deepCopy .Values.observability.instrumentation.openTelemetry.otelCollector -}}
    {{- if eq .Values.observability.instrumentation.openTelemetry.otelCollector.mode "sidecar" -}}
      {{- $_ := set $otelCollConfig "useOperator" true -}}
    {{- end -}}
    {{- /* Dynamically generate the yaml based configuiration for the Otell Collector
        It has multiple sections who's configurations will depend upon which components
        have been enabled, such as Loki for example.
        We need to generate receivers, processors, exporters and services */ -}}
    {{- $receiverType := "" -}}
    {{- $receivers := dict -}}
    {{- $processors := dict -}}
    {{- $exporters := dict -}}
    {{- $service := dict -}}
    {{- $pipelines := dict -}}
    {{- $yamlConfig := dict -}}
    {{- if and (.Values.observability.instrumentation.logging).enabled ((.Values.observability.services.logging).loki).enabled -}}
      {{- $receiverType = "otlpgrpc" -}}
      {{- $lokiResourceLabels := list -}}
      {{- $lokiResourceLabels = append $lokiResourceLabels (dict "name" "namespace" "source" "k8s.namespace.name") -}}
      {{- $lokiResourceLabels = append $lokiResourceLabels (dict "name" "deployment" "source" "k8s.deployment.name") -}}
      {{- $lokiResourceLabels = append $lokiResourceLabels (dict "name" "replicaset" "source" "k8s.replicaset.name") -}}
      {{- $lokiResourceLabels = append $lokiResourceLabels (dict "name" "pod" "source" "k8s.pod.name") -}}
      {{- $lokiResourceLabels = append $lokiResourceLabels (dict "name" "smile.version" "source" "service.version")  -}}

      {{- $deleteAttributes := list -}}
      {{- $deleteAttributes = append $deleteAttributes "host.arch" -}}
      {{- $deleteAttributes = append $deleteAttributes "host.name" -}}
      {{- $deleteAttributes = append $deleteAttributes "os.description" -}}
      {{- $deleteAttributes = append $deleteAttributes "os.type" -}}
      {{- $deleteAttributes = append $deleteAttributes "process.pid" -}}

      {{- $lokiLabels := list -}}
      {{- $attributeActions := list -}}
      {{- range $lokiLabel := $lokiResourceLabels -}}
        {{- if and (hasKey $lokiLabel "source") (ne $lokiLabel.name $lokiLabel.source) -}}
          {{- $attributeActions = append $attributeActions (dict "action" "insert" "key" $lokiLabel.name "from_attribute" $lokiLabel.source) -}}
          {{- $attributeActions = append $attributeActions (dict "action" "delete" "key" $lokiLabel.source) -}}
        {{- end -}}
        {{- $lokiLabels = append $lokiLabels $lokiLabel.name -}}
      {{- end -}}
      {{- if gt (len $lokiLabels) 0 -}}
        {{- $attributeActions = append $attributeActions (dict "action" "insert" "key" "loki.resource.labels" "value" (join "," $lokiLabels)) -}}
      {{- end -}}
      {{- $_ := set $processors "resource/loki" (dict "attributes" $attributeActions) -}}

      {{- $lokiHost := "loki" -}}
      {{- $lokiPort := "3100" -}}
      {{- $_ := set $exporters "loki" (dict "endpoint" (printf "http://%s:%s/loki/api/v1/push" $lokiHost $lokiPort)) -}}

      {{- if eq $receiverType "otlpgrpc" -}}
        {{- $_ := set $receivers "otlp" (dict "protocols" (dict "grpc" dict)) -}}
      {{- end -}}

      {{- $logsPipeline := dict -}}
      {{- $_ := set $logsPipeline "receivers" (list "otlp") -}}
      {{- $_ := set $logsPipeline "processors" (list "resource/loki") -}}
      {{- $_ := set $logsPipeline "exporters"  (list "loki") -}}
      {{- $_ := set $pipelines "logs" $logsPipeline -}}

    {{- end -}}
    {{- $_ := set $yamlConfig "processors" $processors -}}
    {{- $_ := set $yamlConfig "exporters" $exporters -}}
    {{- $_ := set $yamlConfig "receivers" $receivers -}}
    {{- $_ := set $yamlConfig "service" (dict "pipelines" $pipelines) -}}
    {{- $_ := set $otelCollConfig "yamlConfig" $yamlConfig -}}
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
