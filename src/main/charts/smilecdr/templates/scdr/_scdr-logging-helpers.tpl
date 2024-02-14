{{- define "logging.logback.smile-custom-xml.mappedFile" -}}
  {{- $ctx := get . "Values" -}}
  {{- $mappedFile := dict -}}
  {{- if and (hasKey $ctx "logging") -}}
    {{- $loggingConfig := $ctx.logging -}}
    {{- $troubleshootingLoggers := default dict $loggingConfig.troubleshootingLoggers -}}
    {{- $customLoggers := default (dict) $loggingConfig.customLoggers -}}
    {{- $setLoggers := default dict $loggingConfig.setLoggers -}}
    {{- $rawLogConfig := default nil $loggingConfig.rawLogConfig -}}
    {{- $generateLogConfig := false -}}
    {{- if or (gt (len $troubleshootingLoggers) 0) (gt (len $customLoggers) 0) (gt (len $setLoggers) 0) -}}
      {{- $generateLogConfig = true -}}
    {{- end -}}
    {{- if $rawLogConfig -}}
      {{- /* If raw config is provided, we will not generate config at all. */ -}}
      {{- $generateLogConfig = false -}}
    {{- end -}}

    {{- if $generateLogConfig -}}
      {{- /* TODO: Make this conditional. Only use if there are log configs */ -}}
      {{- $generatedConfig := "<included>" -}}
      {{- /* Include default entries that send to STDOUT unless STDOUT is disabled. */ -}}
      {{- if not $loggingConfig.disableStdOut -}}
        {{- $generatedConfig = printf "%s\n%s" $generatedConfig  (include "logging.logback.troubleshootingDefaults" . | indent 2) -}}
      {{- end -}}

      {{- range $theCustomLoggerName, $theCustomLoggerSpec := $customLoggers -}}
        {{- if $theCustomLoggerSpec.enabled -}}
          {{- $output := include "logging.logback.customLogger" (dict "name" $theCustomLoggerName "spec" $theCustomLoggerSpec) -}}
          {{- $generatedConfig = printf "%s\n%s" $generatedConfig  ($output| indent 2) -}}
        {{- end -}}
      {{- end -}}
      {{- range $theTroubleshootingLoggerName, $theTroubleshootingLoggerSpec := $troubleshootingLoggers -}}
        {{- if $theTroubleshootingLoggerSpec.enabled -}}
          {{- $generatedConfig = printf "%s\n%s" $generatedConfig (include "logging.logback.troubleshootingLogger" (dict "name" $theTroubleshootingLoggerName "spec" $theTroubleshootingLoggerSpec) | indent 2) -}}
        {{- end -}}
      {{- end -}}
      {{- range $theSetLoggerName, $theSetLoggerSpec := $setLoggers -}}
        {{- $generatedConfig = printf "%s\n%s" $generatedConfig (include "logging.logback.setLogger" (dict "name" $theSetLoggerName "spec" $theSetLoggerSpec) | indent 2) -}}
      {{- end -}}
      {{- $generatedConfig = printf "%s\n</included>" $generatedConfig -}}
      {{- $mappedFile = dict "data" $generatedConfig "path" "/home/smile/smilecdr/customerlib" -}}
    {{- else if $rawLogConfig -}}
      {{- $mappedFile = dict "data" $rawLogConfig "path" "/home/smile/smilecdr/customerlib" -}}
    {{- end -}}
  {{- end -}}
  {{ $mappedFile | toYaml }}
{{- end -}}


{{- define "logging.logback.customLogger" -}}
  {{- $theLoggerName := get . "name" -}}
  {{- $theLoggerSpec := get . "spec" -}}
  {{- $theLoggerText := printf "<!--\nCustom logger: %s\n-->" $theLoggerName -}}
  {{- $theLoggerLevel := "INFO" -}}
  {{- if hasKey $theLoggerSpec "level" -}}
    {{- if contains (upper $theLoggerSpec.level) "OFF ERROR INFO WARN DEBUG TRACE" -}}
      {{- $theLoggerLevel = (upper $theLoggerSpec.level) -}}
    {{- else -}}
      {{- fail (printf "Logging: `%s` is not a valid logging level for the `%s` logger configuration. Choose from OFF ERROR INFO WARN DEBUG or TRACE" $theLoggerSpec.level $theLoggerName ) -}}
    {{- end -}}
  {{- end -}}
  {{- if ne (upper $theLoggerSpec.target) "STDOUT" -}}
    {{- /* Not logging this to STDOUT so the target is a file name in the log directory instead.
        Build an appender for this target */ -}}
    {{- $asyncAppenderName := upper $theLoggerName -}}
    {{- $syncAppenderName := printf "%s_SYNC" $asyncAppenderName -}}
    {{- $fileNameRoot := default $theLoggerName (trimSuffix ".log" $theLoggerSpec.target) -}}
    {{- /* Build the synchronous appender... */ -}}
    {{- $theLoggerText = printf "%s\n<appender name=\"%s\" class=\"ch.qos.logback.core.rolling.RollingFileAppender\">" $theLoggerText $syncAppenderName -}}
    {{- $theLoggerText = printf "%s\n  <filter class=\"ch.qos.logback.classic.filter.ThresholdFilter\">" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n    <level>%s</level>" $theLoggerText $theLoggerLevel -}}
    {{- $theLoggerText = printf "%s\n  </filter>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  <filter class=\"ca.cdr.api.log.CdrPHISafetyLogFilter\"/>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  <file>${smile.basedir}/log/%s.log</file>" $theLoggerText $fileNameRoot -}}
    {{- $theLoggerText = printf "%s\n  <rollingPolicy class=\"ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n    <fileNamePattern>${smile.basedir}/log/%s.%%d{yyyy-MM-dd}.log.gz</fileNamePattern>" $theLoggerText $fileNameRoot -}}
    {{- $theLoggerText = printf "%s\n    <maxHistory>30</maxHistory>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  </rollingPolicy>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  <encoder>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n    <pattern>%s</pattern>" $theLoggerText $theLoggerSpec.pattern -}}
    {{- $theLoggerText = printf "%s\n  </encoder>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n</appender>" $theLoggerText -}}
    {{- /* Build the asynchronous appender */ -}}
    {{- $theLoggerText = printf "%s\n<appender name=\"%s\" class=\"ch.qos.logback.classic.AsyncAppender\">" $theLoggerText $asyncAppenderName -}}
    {{- $theLoggerText = printf "%s\n  <discardingThreshold>0</discardingThreshold>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  <includeCallerData>false</includeCallerData>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n  <appender-ref ref=\"%s\" />" $theLoggerText $syncAppenderName -}}
    {{- $theLoggerText = printf "%s\n</appender>" $theLoggerText -}}
    {{- /* Build the logger */ -}}
    {{- $theLoggerText = printf "%s\n<logger name=\"%s\" level=\"%s\">" $theLoggerText $theLoggerSpec.path $theLoggerLevel -}}
    {{- $theLoggerText = printf "%s\n  <appender-ref ref=\"%s\"/>" $theLoggerText $asyncAppenderName -}}
    {{- $theLoggerText = printf "%s\n</logger>" $theLoggerText -}}
  {{- else -}}
    {{- /* Using STDOUT so just build the logger */ -}}
    {{- $theLoggerText = printf "%s\n<logger name=\"%s\" level=\"%s\">" $theLoggerText $theLoggerSpec.path $theLoggerLevel -}}
    {{- $theLoggerText = printf "%s\n  <appender-ref ref=\"STDOUT\"/>" $theLoggerText -}}
    {{- $theLoggerText = printf "%s\n</logger>" $theLoggerText -}}
  {{- end -}}
  {{- $theLoggerText -}}
{{- end -}}

{{- define "logging.logback.troubleshootingLogger" -}}
  {{- $theLoggerName := get . "name" -}}
  {{- $theLoggerSpec := get . "spec" -}}
  {{- $theLoggerLevel := "INFO" -}}
  {{- if hasKey $theLoggerSpec "level" -}}
    {{- if contains (upper $theLoggerSpec.level) "OFF ERROR INFO WARN DEBUG TRACE" -}}
      {{- $theLoggerLevel = (upper $theLoggerSpec.level) -}}
    {{- else -}}
      {{- fail (printf "Logging: `%s` is not a valid logging level for the `%s` logger configuration. Choose from OFF ERROR INFO WARN DEBUG or TRACE" $theLoggerSpec.level $theLoggerName ) -}}
    {{- end -}}
  {{- end -}}
  {{- if $theLoggerSpec.enabled -}}
    {{- $loggerDefinitions := include "logging.logback.troubleshootingLoggerDefinitions" . | fromYaml -}}
    {{- /* fail (printf "$loggerDefinitions:\n%s" (toPrettyJson $loggerDefinitions)) */ -}}
    {{- if hasKey $loggerDefinitions $theLoggerName -}}
      {{- $loggerDefinition := get $loggerDefinitions $theLoggerName -}}
      {{- $loggerPath := (default $loggerDefinition.path $theLoggerSpec.path) -}}
      {{- printf "<!-- %s Troubleshooting log." $loggerDefinition.name -}}
      {{- if hasKey $loggerDefinition "description" -}}
        {{- printf "\n  %s -->" $loggerDefinition.description -}}
      {{- else -}}
        {{- printf " -->" -}}
      {{- end -}}
      {{- printf "\n<logger name=\"%s\" level=\"%s\"/>" $loggerPath $theLoggerLevel -}}
    {{- else -}}
      {{- fail (printf "Logging: There is no troubleshooting logger named: `%s`\nPlease choose from the available list:\n%s" $theLoggerName (keys $loggerDefinitions)) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "logging.logback.setLogger" -}}
  {{- $theLoggerName := get . "name" -}}
  {{- $theLoggerSpec := get . "spec" -}}

  {{- printf "<!-- Setting loggers for %s" $theLoggerName -}}
  {{- if hasKey $theLoggerSpec "description" -}}
    {{- printf "\n     %s -->" $theLoggerSpec.description -}}
  {{- else -}}
    {{- printf " -->" -}}
  {{- end -}}
  {{- $theLoggerLevel := "INFO" -}}
  {{- if hasKey $theLoggerSpec "level" -}}
    {{- if contains (upper $theLoggerSpec.level) "OFF ERROR INFO WARN DEBUG TRACE" -}}
      {{- $theLoggerLevel = (upper $theLoggerSpec.level) -}}
    {{- else -}}
      {{- fail (printf "Logging: `%s` is not a valid logging level for the `%s` logger configuration. Choose from OFF ERROR INFO WARN DEBUG or TRACE" $theLoggerSpec.level $theLoggerName ) -}}
    {{- end -}}
  {{- end -}}

  {{- range $thePath := $theLoggerSpec.paths -}}
    {{- printf "\n<logger name=\"%s\" level=\"%s\"/>" $thePath $theLoggerLevel -}}
  {{- end -}}
  {{- printf "" -}}
{{- end -}}

{{- define "logging.logback.troubleshootingDefaults" -}}
<!-- Send all troubleshooting logs to the console for viewing via `docker logs` -->
<logger name="ca.cdr.log">
  <appender-ref ref="STDOUT_SYNC"/>
</logger>
<logger name="ca.uhn.fhir.log">
  <appender-ref ref="STDOUT_SYNC"/>
</logger>
{{- end -}}

{{- define "logging.logback.troubleshootingLoggerDefinitions" -}}

  {{- $loggerDefs := dict -}}
  {{- $defaultLevel := "debug" -}}

  {{- $defs := fromYaml `
      ca.cdr.log.hl7v2_troubleshooting:
        name: HL7V2
      ca.cdr.log.http_troubleshooting:
        name: HTTP
        description: DEBUG will log http access.  TRACE will include more detail including headers.
      ca.cdr.log.security_troubleshooting:
        name: Security
        description: Authentication and Authorization
      ca.cdr.log.subscription_troubleshooting:
        name: Subscription
      ca.cdr.log.livebundle_troubleshooting:
        name: LiveBundle
      ca.uhn.fhir.log.mdm_troubleshooting:
        name: MDM
      ca.cdr.log.channel_import_troubleshooting:
        name: Channel Import
      ca.cdr.log.realtime_export_troubleshooting:
        name: Realtime Export
        description: DEBUG will report export activating including sql queries.\nTRACE will include actual parameter bind values which may contain sensitive information
      ca.cdr.log.fhirgateway_troubleshooting:
        name: FHIR Gateway
      ca.cdr.log.connection_pool_troubleshooting:
        name: Connection Pool
      ca.cdr.log.aws_healthlake_export_troubleshooting:
        name: AWS HealthLake Export
      ca.uhn.fhir.log.batch_troubleshooting:
        name: Batch Framework
      ca.uhn.fhir.log.narrative_generation_troubleshooting:
        name: Narrative Generation
      ca.uhn.fhir.log.terminology_troubleshooting:
        name: Terminology` -}}
  {{- /* Transform the above into usable structure */ -}}
  {{- range $theLoggerKey, $theLoggerDef := $defs -}}
    {{- $newKey := last (splitList "." $theLoggerKey) -}}
    {{- $newDef := dict "name" $theLoggerDef.name "path" $theLoggerKey "level" $defaultLevel "enabled" false -}}
    {{- if hasKey $theLoggerDef "description" -}}
      {{- $_ := set $newDef "description" $theLoggerDef.description -}}
    {{- end -}}
    {{- $_ := set $loggerDefs $newKey $newDef -}}
  {{- end -}}
  {{- $loggerDefs | toYaml -}}
{{- end -}}
