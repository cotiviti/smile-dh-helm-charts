{{- /* PMP Config Helper
    This Helper Template is used to generate `config.json` for the
    member portal and admin portal containers.

    It can take a json or yaml input file as overrides */ -}}

  {{- /* Options on how to merge:
      1. Take a source json file and (optionally) overwrite certain settings
      2.

      In either case, we need a list of values that should be overriden.
      This should probably be defined in the default values file so that it
      is easily customisable.

      Option 1 Scenario:
      - We have a source json, that has entries d, e & f
      - We defined defaults for values a, b, c & d
      - All values must be captured

      ## Individual dict parsing...
      If we loop though all the json entries to build the final config, we will only have d, e & f
      If we loop though all the values entries to build the final config, we will only have a, b, c & d

      Instead, we should use merge.

      ## Merging when final values should take priority from Values file
      Merge both dicts with priority to the values dict.
      You can control which json-sourced values get overwritten by adding/removing them from values file.
      Hard to remove them if they are in default values (Without removing ALL entries and adding them back manually)
      Maybe enable/disable each entry in the values file using some other schema

      ## Merging when final values should take priority from json file
      Merge both dicts with priority to the values dict.
      You can control which default values get overwritten by adding/removing them from json file.
      Although this may be more familiar to those used to the json file config method, this means
      more configuration split, as you NEED to update the json file to make changes.

      ## Maybe have `enabledOverrides` or `disabledOverrides`. Fiddly

      If we say "All config to be done by values file" then we can avoid merging alltogether, but we need a way
      for user to easily add config items to the values file when they are used to using json...

      For this, maybe have the config section under the relevant component.
      It will make the default values file much longer. It's also not too dissimilar from the json file scenario, as we
      still need to solve the problem of which fields to automate.

      Maybe we need a section that just defines which fields are overriden by the chart based on the environment.
      So...

      * `component.memberPortal.config.values` for default static values
      * `component.memberPortal.config.jsonValues` for default values passed in via json.
          These override config.values with a warning notice that they should be moved to the values file
      * `component.memberPortal.config.dynamicValues` for values determined at runtime.
          These should be objects defining how the value is determined maybe.
          There can be an option saying if they can be overridden by values, json or otherwise

      */ -}}

{{- define "component.appConfig" -}}
  {{- $componentName := .componentName -}}
  {{- $currentComponentName := ternary .componentName nil (not (eq .componentName nil)) -}}
  {{- $currentComponent := .Values -}}

  {{- $mergedComponentConfig := dict -}}
  {{- $componentHelmValues := $currentComponent.config.values -}}
  {{- /* Add `dynamicVariables` to the parameters that will be passed in to the iterative appConfig generator template
      Maybe not needed as it should already be there */ -}}
  {{- /* $templateParams = merge $templateParams (dict "dynamicValues" (($component.config).dynamicValues)) */ -}}
  {{- /* Generate and retrieve any dynamically generated values defined in `.Values.[component].config.dynamicValues` */ -}}
  {{- $componentDynamicValues := include "component.appConfigDynamic" . | fromYaml -}}

  {{- /* Do the final merge of all the config sources. */ -}}
  {{- $componentConfigData := dict -}}
  {{- if hasKey $currentComponent.config "jsonValues" -}}
    {{- $componentJsonValues := $currentComponent.config.jsonValues | fromJson -}}
    {{- if eq ($currentComponent.config).jsonOverride "none" -}}
      {{- /* Merge with priority: dynamic, helm json */ -}}
      {{- $componentConfigData = merge $componentDynamicValues $componentHelmValues $componentJsonValues $componentConfigData -}}
    {{- else if eq ($currentComponent.config).jsonOverride "static" -}}
      {{- /* Merge with priority: dynamic, json, helm */ -}}
      {{- $componentConfigData = merge $componentDynamicValues $componentJsonValues $componentHelmValues $componentConfigData -}}
    {{- else if eq ($currentComponent.config).jsonOverride "all" -}}
      {{- /* Merge with priority: json, dynamic, helm */ -}}
      {{- $componentConfigData = merge $componentJsonValues $componentDynamicValues $componentHelmValues $componentConfigData -}}
    {{- end -}}
  {{- else -}}
    {{- /* There is no json file. Load with preference dynamic, helm */ -}}
    {{- $componentConfigData = merge $componentDynamicValues $componentHelmValues $componentConfigData -}}
  {{- end -}}

  {{- $componentConfig := dict "name" $componentName "data" $componentConfigData -}}
  {{- $componentConfig | toYaml -}}
{{- end -}}

{{- /* Due to the nested nature of json config files, this function will
    iteratively build configuration blocks by calling itself for any nested
    map/dict entries */ -}}
{{- define "component.appConfigDynamic" -}}
  {{- $ctx := . -}}
  {{- $componentConfig := dict -}}
  {{- /* $configPath := .configPath */ -}}

  {{- $clientIDGlobal := (get $ctx.Values.externalConfig.oauth.clientIDs $ctx.componentName) -}}
  {{- $clientIDLocal := default $clientIDGlobal $ctx.Values.oauthClientId -}}

  {{- if $ctx.Values.config.dynamicValues -}}
    {{- range $k, $v := $ctx.Values.config.dynamicValues -}}
      {{- $newValue := "" -}}
      {{- if kindIs "map" $v -}}
        {{- if hasKey $v "type" -}}
          {{- if eq $v.type "url" -}}
            {{- /* Auto Generate URL configurations */ -}}
            {{- $hostName := "" -}}
            {{- $path := "" -}}
            {{- if eq $v.host "cdr" -}}
              {{- /* As this chart does not deploy CDR, the cdr hostname needs to be passed
                  in via `Values.externalConfig.smileCdr.hostname` */ -}}
              {{- $hostName = $ctx.Values.externalConfig.smileCdr.hostname -}}
            {{- else if eq $v.host "cms" -}}
              {{- /* As this chart does not deploy Directus,the cms hostname needs to be passed
                  in via `Values.externalConfig.cms.hostname` */ -}}
              {{- $hostName = $ctx.Values.externalConfig.cms.hostname -}}
            {{- else if eq $v.host "issuer" -}}
              {{- /* As this chart does not deploy any IdP components, relevant details need
                  to be passed in via `Values.externalConfig.oauth` */ -}}
              {{- $hostName = $ctx.Values.externalConfig.oauth.issuer -}}
            {{- else if eq $v.host "altAuthHost" -}}
              {{- /* As this chart does not deploy any IdP components, relevant details need
                  to be passed in via `Values.externalConfig.oauth` */ -}}
              {{- $hostName = $ctx.Values.externalConfig.oauth.altAuthHost -}}
            {{- else if eq $v.host "memberPortal" -}}
              {{- $hostName = (index $ctx.Values.components.memberPortal.ingress.hosts 0 ).host -}}
            {{- else if eq $v.host "pmpUserServices" -}}
              {{- $hostName = (index $ctx.Values.components.pmpUserServices.ingress.hosts 0).host -}}

            {{- else -}}
              {{- fail (printf "There is no handler for host of type `%s`. Investigate..." $v.host) -}}
            {{- end -}}
            {{- if hasKey $v "path" -}}
              {{- /* Path parameter substitution currently supports:
                  - fhirPath (Determined by the passed in Helm Chart parameter)
                  - oauthClientId (Determined by client Id of current PMP component) */ -}}
              {{- if contains "$" $v.path -}}
                {{- /* if contains (mustRegexFind "(?:\\${)(.*)(?:})" $v.path) "fhirPath oauthClientId" */ -}}
                {{- $path = regexReplaceAll "\\${fhirPath}"  $v.path $ctx.Values.externalConfig.smileCdr.fhirPath -}}
                {{- /* TODO: Not sure yet if we should get the oauthId from global scope or component scope like below
                    If we do it from global scope, config may be nicer, but then we will need to dynamically add the
                    value to the component object so it can be easily used here */ -}}
                {{- /* Now I have had to reconfigure this, I prefer doing it from the global scope. Maybe allow it from either. */ -}}
                {{- $path = regexReplaceAll "\\${oauthClientId}"  $path $clientIDLocal -}}
              {{- else -}}
                {{- $path = $v.path -}}
              {{- end -}}
            {{- end -}}
            {{- $newValue = printf "%s%s" $hostName $path -}}
          {{- else if eq $v.type "idpGroups" -}}
            {{- /* Auto Generate idpGroups configurations */ -}}
            {{- /* Determine how to find the correct value for this
                  In the meantime, just use `cognito:groups` */ -}}
            {{- $newValue = "cognito:groups" -}}
          {{- else if eq $v.type "authId" -}}
            {{- /* Auto Generate authId configurations */ -}}
            {{- /* As this chart does not configure the IdP, the ids need
                to be passed in via `Values.components.<componentname>.oauthClientId` */ -}}
            {{- $newValue = $clientIDLocal -}}
          {{- else if eq $v.type "cognitouserpoolid" -}}
            {{- /* Auto Generate poolid configurations */ -}}
            {{- /* As this chart does not configure the IdP, the ids need
                to be passed in via `Values.externalConfig.oauth.cognitoUserPool` */ -}}
            {{- $newValue = $ctx.Values.externalConfig.oauth.cognitoUserPool -}}
          {{- else if eq $v.type "list[token_parameter]" -}}
            {{- /* Auto Generate token parameter list configurations */ -}}
            {{- $parameterList := list -}}
            {{- range $listVal := $v.parameters -}}
              {{- /* If the IdP is AWS Cognito, custom token params must be prefixed
                  by `custom:`. */ -}}
              {{- if eq $ctx.Values.externalConfig.oauth.idpVendor "cognito" -}}
                {{- $parameterList = append $parameterList (printf "custom:%s" $listVal) -}}
              {{- else -}}
                {{- $parameterList = append $parameterList $listVal -}}
              {{- end -}}
            {{- end -}}
            {{- $newValue = $parameterList -}}
          {{- end -}}
        {{- else -}}
          {{- /* Update dynamicValues context and iterate as this is not a dynamic value entry (identified by the absense of the `type` key) */ -}}
          {{- $localTemplateParams := deepCopy $ctx -}}
          {{- $_ := set $localTemplateParams.Values.config "dynamicValues" $v -}}
          {{- $newValue = (include "component.appConfigDynamic" $localTemplateParams) | fromYaml -}}
        {{- end -}}

      {{- else if kindIs "string" $v -}}
        {{- /* Catch static definitions in dynamicValues section */ -}}
        {{- $configPath := printf "Values.components.%s.config.dynamicValues" $ctx.componentName -}}
        {{- fail (printf "Static values should not be defined in `dynamicValues` section. Define `%s` in `values` section instead!" (printf "%s.%s" $configPath $k) ) -}}
      {{- end -}}
      {{- $_ := set $componentConfig $k $newValue -}}

    {{- end -}}
  {{- end -}}
  {{- $componentConfig | toYaml -}}
{{- end -}}

{{- define "component.configMap" -}}
  {{- $configMap := dict -}}
  {{- $currentComponentName := ternary .componentName nil (not (eq .componentName nil)) -}}
  {{- if hasKey .Values "config" -}}
    {{- $currentComponent := .Values -}}
    {{- if $currentComponent.enabled -}}
      {{- $currentComponentConfig := $currentComponent.config -}}
      {{- $configFormat := default "json" $currentComponentConfig.type -}}
      {{- if eq $configFormat "json" -}}
        {{- /* $_ := set $configMaps $component (include "pmp.appConfig" (dict "Values" .Values "componentName" $component) | fromYaml) */ -}}
        {{- $configMap = (include "component.appConfig" . | fromYaml) -}}
        {{- $_ := set $configMap "hash" (include "pmp.getConfigMapNameHashSuffix" (dict "Values" $currentComponent "data" $configMap.data)) -}}
        {{- $configMapName := printf "%s-pmp-%s%s" .Release.Name (include "pmp.getNormalisedResourceName" $configMap.name) $configMap.hash -}}
        {{- $_ := set $configMap "configMapName" $configMapName -}}
        {{- $configFileName := $currentComponentConfig.fileName -}}
        {{- $_ := set $configMap "configFileName" $configFileName -}}
      {{- else -}}
        {{- fail (printf "Config type `%s` in component `%s` is not supported." $configFormat $currentComponentName) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $configMap | toYaml -}}
{{- end -}}

{{- define "component.fileConfigMaps" -}}
  {{- $fileCfgMaps := list -}}
  {{- $configMap := (include "component.configMap" . | fromYaml) -}}
  {{- if not (empty $configMap) -}}
    {{- $fileCfgMaps = append $fileCfgMaps $configMap -}}
  {{- end -}}
  {{- $fileCfgMaps | toYaml -}}
{{- end -}}
