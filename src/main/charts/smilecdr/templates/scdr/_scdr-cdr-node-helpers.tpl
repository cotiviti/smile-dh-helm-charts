{{/*
Define CDR Nodes
*/}}

{{- define "smilecdr.cdrNodes" -}}
  {{- $cdrNodes := dict -}}
  {{- $rootCTX := . -}}
  {{- $globalValues := deepCopy .Values -}}
  {{- $numEnabledNodes := 0 -}}
  {{- range $theCdrNodeName, $theCdrNodeSpec := $globalValues.cdrNodes -}}
    {{- if not (hasKey $theCdrNodeSpec "enabled" ) -}}
      {{- fail (printf "Node %s does not have `enabled` key set" $theCdrNodeName) -}}
    {{- end -}}
    {{- if $theCdrNodeSpec.enabled -}}
      {{- $numEnabledNodes = add $numEnabledNodes 1 -}}
    {{- end -}}
  {{- end -}}
  {{- if lt $numEnabledNodes 1 -}}
    {{- fail "\nYou have not enabled any Smile CDR Nodes.\n\nYou must enable at least one in `cdrNodes`" -}}
  {{- end -}}
  {{- range $theCdrNodeName, $theCdrNodeSpec := $globalValues.cdrNodes -}}
    {{- if $theCdrNodeSpec.enabled -}}
      {{- /* We have a lot to do in here...
          * Determine any settings, based on root, overridden by locals
          * Same for the modules
          * Clustermgr module can only come from root `modules.clustermgr`
          * Other modules can be a merge of root modules and per-node modules

          Step1: General cdrNode configs
          * labels
          * autoscaling
          * replicaCount
          * selectorLabels
          * podAnotations
          * etc...
          Maybe it's just 'everything' except...
          * crunchypgo
          * cdrNodes (duh)
          * messageBroker

          Far simpler this way!

          Step2: Generated configs

          Step3: CDR Node module configs

          TODO:
          * Clustermgr should be defined in some global context
          * Clustermgr database update should only be enabled on 'admin' node
            * Potentially, it should also be disabled there, but then we need the upgrade Job
          * Persistence databases should be implemented on admin node
            * So that you can control batch processing from web admin node
            * Admin CDR node is then responsible for DB schema updates (Or the admin CDR node upgrade 'job')
          * Should use a single service account if only defined globally.
            * Only use separate service account if explicitly defined.
          * Config maps:
            * Any in root context should be included as-is
              * Unless the same file is defined in a nodespec
            This is tricky, as we need to pass the separate files in to Helm using a different key,
            so we need to iterate the global map and the nodeSpec map to determine the canonical list
            of files.
          */ -}}

      {{- /* Merge everything from 'root' of config */ -}}
      {{- /* This merge gives precedence to the nodeSpec values.*/ -}}
      {{- $parsedNodeValues := mustMergeOverwrite (deepCopy (omit $globalValues "cdrNodes")) (deepCopy (omit $theCdrNodeSpec "ingress")) -}}

      {{- $_ := set $parsedNodeValues "cdrNodeName" $theCdrNodeName -}}
      {{- $_ := set $parsedNodeValues "resourceSuffix" (printf "scdrnode-%s" $theCdrNodeName) -}}
      {{- if $parsedNodeValues.oldResourceNaming -}}
          {{- if gt $numEnabledNodes 1 -}}
            {{- fail "\nYou cannot use the old-style resource naming with a multi-node configuration.\n\nYou must either configure to use a single node, or disable `oldResourceNaming`.\n" -}}
          {{- end -}}
        {{- $_ := set $parsedNodeValues "resourceSuffix" (printf "scdr") -}}
      {{- end -}}

      {{- /* TODO: Ensure cdrNodeId is unique */ -}}
      {{- $_ := set $parsedNodeValues "cdrNodeId" (default $theCdrNodeName $theCdrNodeSpec.name) -}}
      {{- /* Or just don't allow overriding it with `name`? */ -}}


      {{- /* Set CDR Node specific labels */ -}}
      {{- $cdrNodeLabels := include "smilecdr.labels" $rootCTX | fromYaml -}}
      {{- $cdrNodeSelectorLabels := include "smilecdr.selectorLabels" $rootCTX | fromYaml -}}

      {{- /* TODO: Refactor this code when the `oldResourceNaming` option is removed */ -}}
      {{- if not $parsedNodeValues.oldResourceNaming -}}
          {{- $_ := set $cdrNodeLabels "smilecdr/nodeName" $theCdrNodeName -}}
          {{- $_ := set $cdrNodeSelectorLabels "smilecdr/nodeName" $theCdrNodeName -}}
      {{- end -}}

      {{- $_ := set $parsedNodeValues "cdrNodeLabels" $cdrNodeLabels -}}
      {{- $_ := set $parsedNodeValues "cdrNodeSelectorLabels" $cdrNodeSelectorLabels -}}

      {{- /* Some CDR node 'Values' are set using external helper functions.
          Some of them only require the local context, but some also require
          access to the root context. This helper object can be passed in to
          any of the new 'node' helpers so that they have access to both
          contexts.

          Orrrrr... We simply pass a modified root context, where the local 'Values'
          is merged (With priority to local values)
          This requires less special case handling of helpers...

          ** UPDATE ** Indeed, keeping track of whether a given helper needs a root context or just
          The local values is proving troublesome. Refactor all helpers to use a full root context.
          */ -}}

      {{- /* Note: Only doing the deepCopy on the root ctx.
          $parsedNodeValues is merged as a reference, so anything updated
          will be available in the context for further includes*/ -}}
      {{- $cdrNodeHelperCTX := mustMergeOverwrite (deepCopy (omit $rootCTX "Values")) (dict "Values" $parsedNodeValues) -}}

      {{- /* Prepare a canonical list of mappedFiles */ -}}
      {{- /*
          Let's use the example of logback.xml for now.
          ```
          mappedFiles:
            logback.xml:
              path: /home/smile/smilecdr/classes
            someOtherFile.js:
              path: /home/smile/smilecdr/classes
          cdrNodes:
            admin: {/config/}
            fhir:
              mappedFiles:
                logback-fhirnode.xml:
                  fileName: logback.xml
                  path: /home/smile/smilecdr/classes
          ```
          We would expect the Admin CDR node to have logback.xml and someOtherFile.js
          We would expect the FHIR CDR node to have logback-fhir.xml (Mounted as logback.xml) and someOtherFile.js

          Step 1 - Scan the nodeSpec to see if it has any mapped files with `fileName` key. (Ignore if the key matches the mappedFiles key)
          Step 2 -   If it does have such an entry, check to see if the global mappedFiles for the following:
                        * The dict entry has the same name as the `fileName` key from the CDR node spec. (In this case, we are overriding and not using the global one)
                        * If it does, remove the global mappedFiles entry.
          Step 3 - Scan the global mappedFiles for any entries that do not have a 'path' set.
                  (These are entries that have been passed in using --set-file, but have not been defined in the global mappedFiles as they are used in an override)
          Step 4 -   If one of these entries is not the same as one of our nodeSpec entries, then remove it.

          Step 5 - After this, we should be able to just merge

          */ -}}
      {{- /* Scan for potentially overridden entries. Step 1 from above */ -}}
      {{- range $cdrNodeMappedFileName, $cdrNodeMappedFileSpec := $theCdrNodeSpec.mappedFiles -}}
        {{- if hasKey $cdrNodeMappedFileSpec "fileName" -}}
          {{- $fileName := $cdrNodeMappedFileSpec.fileName -}}
          {{- /* Step 2 */ -}}
          {{- range $globalMappedFileName, $globalMappedFileSpec := $globalValues.mappedFiles -}}
            {{- $globalFileName := ternary $globalMappedFileSpec.fileName $globalMappedFileName (hasKey $globalMappedFileSpec "fileName") -}}
            {{- if eq $globalFileName $fileName -}}
              {{- /* We have found a globally defined file that we want to override
                    Remove it from the parsed list */ -}}
              {{- /* TODO: Make this a deep copy if it affects the map outside the CDR node context */ -}}
              {{- $_ := unset $parsedNodeValues.mappedFiles $globalMappedFileName -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- /* Step3 */ -}}
      {{- range $globalMappedFileName, $globalMappedFileSpec := $globalValues.mappedFiles -}}
        {{- if not (hasKey $globalMappedFileSpec "path") -}}
          {{- /* If the global mapped file name is not in the list of our CDR node mapped keys (or if we don't even have any),
                 then it's not required. */ -}}
          {{- if or (not (hasKey $theCdrNodeSpec "mappedFiles")) (not (hasKey $theCdrNodeSpec.mappedFiles $globalMappedFileName )) -}}
            {{- $_ := unset $parsedNodeValues.mappedFiles $globalMappedFileName -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- /* Add autogenerated logback-smile-custom.xml to list of mapped Files */ -}}
      {{- with (include "logging.logback.smile-custom-xml.mappedFile" $cdrNodeHelperCTX | fromYaml ) -}}
        {{- $_ := set $parsedNodeValues.mappedFiles "logback-smile-custom.xml" . -}}
      {{- end -}}
      {{- $_ := set $parsedNodeValues "imagePullSecretsList" (include "imagePullSecretsList" $cdrNodeHelperCTX | fromYamlArray ) -}}
      {{- $_ := set $parsedNodeValues "serviceAccountName" (include "smilecdr.serviceAccountName" $cdrNodeHelperCTX) -}}

      {{- $_ := set $parsedNodeValues "initContainers" (include "smilecdr.initContainers" $cdrNodeHelperCTX | fromYamlArray) -}}

      {{- $_ := set $parsedNodeValues "certificates" (include "certmanager.certificates" $cdrNodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "envVars" (include "smilecdr.envVars" $cdrNodeHelperCTX | fromYamlArray) -}}

      {{- $_ := set $parsedNodeValues "services" (include "smilecdr.services" $cdrNodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "containerPorts" (include "smilecdr.containerPorts" $cdrNodeHelperCTX | fromYamlArray) -}}

      {{- /* Include container probe definitions */ -}}
      {{- $_ := set $parsedNodeValues "startupProbe" (include "smilecdr.startupProbe" $cdrNodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "readinessProbe" (include "smilecdr.readinessProbe" $cdrNodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "livenessProbe" (include "smilecdr.livenessProbe" $cdrNodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "propertiesData" (include "smilecdr.cdrConfigData" $cdrNodeHelperCTX) -}}
      {{- $cmHashSuffix := ternary (printf "-%s" (include "smilecdr.getHashSuffix" $parsedNodeValues.propertiesData)) "" $parsedNodeValues.autoDeploy -}}
      {{- $_ := set $parsedNodeValues "configMapName" (printf "%s%s" ($parsedNodeValues.cdrNodeId | lower) $cmHashSuffix) -}}
      {{- $_ := set $parsedNodeValues "configMapResourceSuffix" (printf "scdrnode-%s" $parsedNodeValues.configMapName) -}}
      {{- /* TODO: Remove when `oldResourceNaming` is removed */ -}}
      {{- if $parsedNodeValues.oldResourceNaming -}}
          {{- $cmHashSuffix = ternary (printf "-%s" (sha256sum $parsedNodeValues.propertiesData)) "" $parsedNodeValues.autoDeploy -}}
          {{- $_ := set $parsedNodeValues "configMapName" (printf "%s%s" ($parsedNodeValues.cdrNodeId | lower) $cmHashSuffix) -}}
          {{- $_ := set $parsedNodeValues "configMapResourceSuffix" (printf "scdr-%s-node%s" ($parsedNodeValues.cdrNodeId | lower) $cmHashSuffix) -}}
      {{- end -}}

      {{- $_ := set $parsedNodeValues "deploymentAnnotations" (include "smilecdr.annotations.deployment" $cdrNodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "podAnnotations" (include "smilecdr.annotations.pod" $cdrNodeHelperCTX | fromYaml) -}}

      {{- /* Set Kafka Configurations for CDR Node */ -}}
      {{- $_ := set $parsedNodeValues "kafka" (include "kafka.config" $cdrNodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "volumeMounts" (include "smilecdr.volumeMounts" $cdrNodeHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedNodeValues "volumes" (include "smilecdr.volumes" $cdrNodeHelperCTX | fromYamlArray) -}}

      {{- /* Sane pod topologySpreadConstraints */ -}}
      {{- if not $parsedNodeValues.disableDefaultTopologyConstraints -}}
      {{- /* if and (hasKey $parsedNodeValues "enableDefaultTopologyConstraints") $parsedNodeValues.enableDefaultTopologyConstraints */ -}}
        {{- $constraintDefaults := dict "maxSkew" 1 "labelSelector" (dict "matchLabels" $cdrNodeSelectorLabels) "matchLabelKeys" (list "pod-template-hash") -}}
        {{- $zoneConstraint := merge (deepCopy $constraintDefaults) (dict "topologyKey" "topology.kubernetes.io/zone" "whenUnsatisfiable" "ScheduleAnyway") -}}
        {{- $nodeConstraint := merge (deepCopy $constraintDefaults) (dict "topologyKey" "kubernetes.io/hostname" "whenUnsatisfiable" "ScheduleAnyway") -}}
        {{- $defaultConstraints := (list $zoneConstraint $nodeConstraint) -}}
        {{- if not (hasKey $parsedNodeValues "topologySpreadConstraints") -}}
          {{- $_ := set $parsedNodeValues "topologySpreadConstraints" $defaultConstraints -}}
        {{- /* There is not much of a use-case to define new topology contraints in *addition* to the defaults. So we just use the defaults OR the provided ones */ -}}
        {{- /* else -}}
          {{- $_ := set $parsedNodeValues "topologySpreadConstraints" (uniq (concat $defaultConstraints $parsedNodeValues.topologySpreadConstraints)) */ -}}
        {{- end -}}
      {{- end -}}

      {{- /* $ingressConfig := dict "annotations" (include "ingress.annotations" $cdrNodeHelperCTX | fromYaml) -}}
      {{- $_ := set $ingressConfig "hosts" (include "ingress.hosts" $cdrNodeHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedNodeValues "ingress" $ingressConfig */ -}}

      {{- /* $_ := set $cdrNodes $theCdrNodeName $parsedNodeValues */ -}}
      {{- $_ := set $cdrNodes $theCdrNodeName $cdrNodeHelperCTX -}}
    {{- end -}}
  {{- end -}}
  {{- $cdrNodes | toYaml -}}
{{- end -}}
