{{/*
Depending on the Smile CDR cluster architecture being used, it only makes
sense to use certain endpoints for the readiness probe.
Due to some healthcheck endpoints not working out-of-the-box with anon
access, we had to choose a sensible default service to use for this.
Rather than hard-coding to a suitable module, this should be defined in
the module definition using `enableReadinessProbe: true`
*/}}
{{- define "smilecdr.readinessProbe" -}}
  {{- $numProbes := 0 -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- range $k, $v := $modules -}}
    {{- /* If module has an enabled endpoint. */ -}}
    {{- if (($v.service).enabled) -}}
      {{- if and (hasKey $v "enableReadinessProbe") ($v.enableReadinessProbe) -}}
        {{- /* Derive & define values for the readiness probe. */ -}}
        {{- if gt $numProbes 0 -}}
          {{- fail "You can only define one readiness probe per node. Review your module configuration and ensure only one module has `enableReadinessProbe` set to true" -}}
        {{- else -}}
          {{- $numProbes = add1 $numProbes -}}
httpGet:
  path: {{ printf "%s%s%s" (default "/" $.Values.specs.rootPath) $v.config.context_path (default "/endpoint-health" (($v.config.endpoint_health).path )) }}
  port: {{ $v.config.port }}
timeoutSeconds: {{ default 10 ($.Values.readinessProbe).periodSeconds }}
failureThreshold: {{ default 2 ($.Values.readinessProbe).failureThreshold }}
periodSeconds: {{ default 10 ($.Values.readinessProbe).periodSeconds }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if eq $numProbes 0 -}}
    {{- fail "You must define one readiness probe per node. Review your module configuration and ensure an enabled module with a service has `enableReadinessProbe` set to true" -}}
  {{- end -}}
{{- end -}}

{{/*
Define Smile CDR environment variables

Note:
This template simply collates the environment variables defined elsewhere to
provide a single entry point.
*/}}
{{- define "smilecdr.envVars" -}}
  {{- $envVars := list -}}
  {{- /* Include DB env vars */ -}}
  {{- $envVars = concat $envVars (include "smilecdr.dbEnvVars" . | fromYamlArray ) -}}
  {{- /* Include kafka env vars - This is for key store passwords, if required */ -}}
  {{- $envVars = concat $envVars (include "kafka.envVars" . | fromYamlArray ) -}}
  {{- /* Include global extra env vars */ -}}
  {{- $envVars = concat $envVars .Values.extraEnvVars -}}
  {{- /* Include JVM settings */ -}}
  {{- with (include "smilecdr.jvmargs" . ) -}}
    {{- $envVars = append $envVars (dict "name" "JVMARGS" "value" .) -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}

{{/*
Define all init containers

Note:
This template simply collates the init containers defined elsewhere to
provide a single entry point.
*/}}
{{- define "smilecdr.initContainers" -}}
  {{- $initContainers := list -}}

  {{- /* Special handling is required for using `concat` on lists that could remain empty.
      This is due to an unresolved bug in the sprig library: https://github.com/helm/helm/issues/10699
      If you `concat` multiple lists, the `toYaml` function will ultimately convert it to `null`
      instead of `[]`, causing linting errors.  */ -}}

  {{- with (include "smilecdr.initFileContainers" . | fromYamlArray ) -}}
    {{- $initContainers = concat $initContainers . -}}
  {{- end -}}
  {{- /* Uncomment once migration containers (i.e. Zero Outage Upgrades) are implemented */ -}}
  {{- /* $initContainers = append $initContainers (include "smilecdr.initMigrateContainers" . | fromYaml ) */ -}}
  {{- toYaml $initContainers -}}
{{- end -}}

{{/*
Generate Helm Chart Warnings

Use this for generating deprecation notices and other warnings about the configuration being used.
*/}}
{{- define "chartWarnings" -}}
  {{- $warningMessage := "" -}}
  {{- /* Check for using unsupported database propertysource mode */ -}}
  {{- if ((include "smilecdr.nodeSettings" . | fromYaml).config).database -}}
    {{- $warningMessage = printf "%s\n\nWARNING: `config.database` is enabled" $warningMessage -}}
    {{- $warningMessage = printf "%s\n This mode is unsupported and not recommended for use when deploying using Helm" $warningMessage -}}
    {{- $warningMessage = printf "%s\n Possible side effects that you may encounter with this mode enabled are:" $warningMessage -}}
    {{- $warningMessage = printf "%s\n  * If modules are added or altered in the console, the environment will" $warningMessage -}}
    {{- $warningMessage = printf "%s\n    be in a state of drift compared to the Helm Chart values." $warningMessage -}}
    {{- $warningMessage = printf "%s\n  * It will not be possible to update certain module configurations that" $warningMessage -}}
    {{- $warningMessage = printf "%s\n    affect the supporting infrastructure (i.e. context roots, ports, databases)" $warningMessage -}}
    {{- $warningMessage = printf "%s\n  * In the event of drift occurring, reverting this mode to `disabled` may then " $warningMessage -}}
    {{- $warningMessage = printf "%s\n    lead to unpredictable behaviour that could result in modules being " $warningMessage -}}
    {{- $warningMessage = printf "%s\n    incorrectly configured, resulting to critical system faults." $warningMessage -}}
  {{- end -}}
  {{- /* Check for using old image pull credentials */ -}}
  {{- if hasKey .Values.image "credentials" -}}
    {{- $warningMessage = printf "%s\n\nDEPRECATED: `image.credentials`" $warningMessage -}}
    {{- $warningMessage = printf "%s\n The use of `image.credentials` has been deprecated. Support for this will be" $warningMessage -}}
    {{- $warningMessage = printf "%s\n removed in a future version of the Helm Chart. Please use `image.pullSecrets` instead." $warningMessage -}}
    {{- $warningMessage = printf "%s\n Refer to the docs for more info on how to configure image pull secrets." $warningMessage -}}
  {{- end -}}
  {{- /* Check for module mis-configurations. */ -}}
  {{- $modules := include "smilecdr.modules" . | fromYaml -}}
  {{- range $k, $v := $modules -}}
    {{- $moduleConfig := $v.config -}}
    {{- /* Check for using `base_url.fixed` in unsupported fashion. */ -}}
    {{- if and (hasKey $moduleConfig "base_url.fixed") (eq (get $moduleConfig "base_url.fixed") "localhost") -}}
      {{- $warningMessage = printf "%s\n\nWARNING: `base_url.fixed` is set to `localhost` in %s module." $warningMessage $k -}}
      {{- $warningMessage = printf "%s\n When overriding `base_url.fixed` to this value, the `Location`" $warningMessage -}}
      {{- $warningMessage = printf "%s\n header and any embedded links will only work when being accessed" $warningMessage -}}
      {{- $warningMessage = printf "%s\n from the same pod. If you are doing this to use the FHIR Gateway" $warningMessage -}}
      {{- $warningMessage = printf "%s\n module, you will not be able to take advantage of 'fanning out' to" $warningMessage -}}
      {{- $warningMessage = printf "%s\n use multiple pods. It's suggested to unset `base_url.fixed` in your" $warningMessage -}}
      {{- $warningMessage = printf "%s\n values file and allow the Helm Chart to configure it automatically." $warningMessage -}}
    {{- end -}}
  {{- end -}}
  {{- /* If there are any warnings, output them with a nice header. */ -}}
  {{- if ne (len $warningMessage) 0 -}}
    {{- $warningMessage = printf "\n***************************%s" $warningMessage -}}
    {{- $warningMessage = printf "\n*** HELM CHART WARNINGS ***%s" $warningMessage -}}
    {{- $warningMessage = printf "\n***************************%s" $warningMessage -}}
    {{- $warningMessage -}}
  {{- end -}}
{{- end -}}
