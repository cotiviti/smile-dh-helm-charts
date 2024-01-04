{{/*
Define CDR Nodes
*/}}

{{- define "smilecdr.nodes" -}}
  {{- $nodes := dict -}}
  {{- $rootCTX := . -}}
  {{- $globalValues := deepCopy .Values -}}
  {{- $numEnabledNodes := 0 -}}
  {{- range $theNodeName, $theNodeSpec := $globalValues.cdrNodes -}}
    {{- if not (hasKey $theNodeSpec "enabled" ) -}}
      {{- fail (printf "Node %s does not have `enabled` key set" $theNodeName) -}}
    {{- end -}}
    {{- if $theNodeSpec.enabled -}}
      {{- $numEnabledNodes = add $numEnabledNodes 1 -}}
    {{- end -}}
  {{- end -}}
  {{- if lt $numEnabledNodes 1 -}}
    {{- $fff := $numEnabledNodes.helpme -}}
    {{- fail "\nYou have not enabled any Smile CDR Nodes.\n\nYou must enable at least one in `cdrNodes`" -}}
  {{- end -}}
  {{- range $theNodeName, $theNodeSpec := $globalValues.cdrNodes -}}
    {{- if $theNodeSpec.enabled -}}
      {{- /* We have a lot to do in here...
          * Determine any settings, based on root, overridden by locals
          * Same for the modules
          * Clustermgr module can only come from root `modules.clustermgr`
          * Other modules can be a merge of root modules and per-node modules

          Step1: General node configs
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

          Step3: Node module configs

          TODO:
          * Clustermgr should be defined in some global context
          * Clustermgr database update should only be enabled on 'admin' node
            * Potentially, it should also be disabled there, but then we need the upgrade Job
          * Persistence databases should be implemented on admin node
            * So that you can control batch processing from web admin node
            * Admin node is then responsible for DB schema updates (Or the admin node upgrade 'job')
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
      {{- $parsedNodeValues := mustMergeOverwrite (deepCopy (omit $globalValues "cdrNodes")) (deepCopy (omit $theNodeSpec "ingress")) -}}

      {{- $_ := set $parsedNodeValues "nodeName" $theNodeName -}}
      {{- $_ := set $parsedNodeValues "resourceSuffix" (printf "scdrnode-%s" $theNodeName) -}}
      {{- if $parsedNodeValues.oldResourceNaming -}}
          {{- if gt $numEnabledNodes 1 -}}
            {{- fail "\nYou cannot use the old-style resource naming with a multi-node configuration.\n\nYou must either configure to use a single node, or disable `oldResourceNaming`.\n" -}}
          {{- end -}}
        {{- $_ := set $parsedNodeValues "resourceSuffix" (printf "scdr") -}}
      {{- end -}}

      {{- /* TODO: Ensure nodeId is unique */ -}}
      {{- $_ := set $parsedNodeValues "nodeId" (default $theNodeName $theNodeSpec.name) -}}
      {{- /* Or just don't allow overriding it with `name`? */ -}}


      {{- /* Set CDR Node specific labels */ -}}
      {{- $cdrNodeLabels := include "smilecdr.labels" $rootCTX | fromYaml -}}
      {{- $cdrNodeSelectorLabels := include "smilecdr.selectorLabels" $rootCTX | fromYaml -}}

      {{- /* TODO: Refactor this code when the `oldResourceNaming` option is removed */ -}}
      {{- if not $parsedNodeValues.oldResourceNaming -}}
          {{- $_ := set $cdrNodeLabels "smilecdr/nodeName" $theNodeName -}}
          {{- $_ := set $cdrNodeSelectorLabels "smilecdr/nodeName" $theNodeName -}}
      {{- end -}}

      {{- $_ := set $parsedNodeValues "cdrNodeLabels" $cdrNodeLabels -}}
      {{- $_ := set $parsedNodeValues "cdrNodeSelectorLabels" $cdrNodeSelectorLabels -}}

      {{- /* Some node 'Values' are set using external helper functions.
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
      {{- $nodeHelperCTX := mustMergeOverwrite (deepCopy (omit $rootCTX "Values")) (dict "Values" $parsedNodeValues) -}}

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
          We would expect the Admin node to have logback.xml and someOtherFile.js
          We would expect the FHIR node to have logback-fhir.xml (Mounted as logback.xml) and someOtherFile.js

          Step 1 - Scan the nodeSpec to see if it has any mapped files with `fileName` key. (Ignore if the key matches the mappedFiles key)
          Step 2 -   If it does have such an entry, check to see if the global mappedFiles for the following:
                        * The dict entry has the same name as the `fileName` key from the node spec. (In this case, we are overriding and not using the global one)
                        * If it does, remove the global mappedFiles entry.
          Step 3 - Scan the global mappedFiles for any entries that do not have a 'path' set.
                  (These are entries that have been passed in using --set-file, but have not been defined in the global mappedFiles as they are used in an override)
          Step 4 -   If one of these entries is not the same as one of our nodeSpec entries, then remove it.

          Step 5 - After this, we should be able to just merge

          */ -}}
      {{- /* Scan for potentially overridden entries. Step 1 from above */ -}}
      {{- range $nodeMappedFileName, $nodeMappedFileSpec := $theNodeSpec.mappedFiles -}}
        {{- if hasKey $nodeMappedFileSpec "fileName" -}}
          {{- $fileName := $nodeMappedFileSpec.fileName -}}
          {{- /* Step 2 */ -}}
          {{- range $globalMappedFileName, $globalMappedFileSpec := $globalValues.mappedFiles -}}
            {{- $globalFileName := ternary $globalMappedFileSpec.fileName $globalMappedFileName (hasKey $globalMappedFileSpec "fileName") -}}
            {{- if eq $globalFileName $fileName -}}
              {{- /* We have found a globally defined file that we want to override
                    Remove it from the parsed list */ -}}
              {{- /* TODO: Make this a deep copy if it affects the map outside the node context */ -}}
              {{- $_ := unset $parsedNodeValues.mappedFiles $globalMappedFileName -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- /* Step3 */ -}}
      {{- range $globalMappedFileName, $globalMappedFileSpec := $globalValues.mappedFiles -}}
        {{- if not (hasKey $globalMappedFileSpec "path") -}}
          {{- /* If the global mapped file name is not in the list of our node mapped keys (or if we don't even have any),
                 then it's not required. */ -}}
          {{- if or (not (hasKey $theNodeSpec "mappedFiles")) (not (hasKey $theNodeSpec.mappedFiles $globalMappedFileName )) -}}
            {{- $_ := unset $parsedNodeValues.mappedFiles $globalMappedFileName -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- $_ := set $parsedNodeValues "imagePullSecretsList" (include "imagePullSecretsList" $nodeHelperCTX | fromYamlArray ) -}}
      {{- $_ := set $parsedNodeValues "serviceAccountName" (include "smilecdr.serviceAccountName" $nodeHelperCTX) -}}

      {{- $_ := set $parsedNodeValues "initContainers" (include "smilecdr.initContainers" $nodeHelperCTX | fromYamlArray) -}}

      {{- $_ := set $parsedNodeValues "envVars" (include "smilecdr.envVars" $nodeHelperCTX | fromYamlArray) -}}

      {{- $_ := set $parsedNodeValues "services" (include "smilecdr.services" $nodeHelperCTX | fromYaml) -}}

      {{- /* Include container probe definitions */ -}}
      {{- $_ := set $parsedNodeValues "startupProbe" (include "smilecdr.startupProbe" $nodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "readinessProbe" (include "smilecdr.readinessProbe" $nodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "livenessProbe" (include "smilecdr.livenessProbe" $nodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "propertiesData" (include "smilecdr.cdrConfigData" $nodeHelperCTX) -}}
      {{- $cmHashSuffix := ternary (printf "-%s" (include "smilecdr.getHashSuffix" $parsedNodeValues.propertiesData)) "" $parsedNodeValues.autoDeploy -}}
      {{- $_ := set $parsedNodeValues "configMapName" (printf "%s%s" ($parsedNodeValues.nodeId | lower) $cmHashSuffix) -}}
      {{- $_ := set $parsedNodeValues "configMapResourceSuffix" (printf "scdrnode-%s" $parsedNodeValues.configMapName) -}}
      {{- /* TODO: Remove when `oldResourceNaming` is removed */ -}}
      {{- if $parsedNodeValues.oldResourceNaming -}}
          {{- $cmHashSuffix = ternary (printf "-%s" (sha256sum $parsedNodeValues.propertiesData)) "" $parsedNodeValues.autoDeploy -}}
          {{- $_ := set $parsedNodeValues "configMapName" (printf "%s%s" ($parsedNodeValues.nodeId | lower) $cmHashSuffix) -}}
          {{- $_ := set $parsedNodeValues "configMapResourceSuffix" (printf "scdr-%s-node%s" ($parsedNodeValues.nodeId | lower) $cmHashSuffix) -}}
      {{- end -}}

      {{- $_ := set $parsedNodeValues "deploymentAnnotations" (include "smilecdr.annotations.deployment" $nodeHelperCTX | fromYaml) -}}
      {{- $_ := set $parsedNodeValues "podAnnotations" (include "smilecdr.annotations.pod" $nodeHelperCTX | fromYaml) -}}

      {{- /* Set Kafka Configurations for CDR Node */ -}}
      {{- $_ := set $parsedNodeValues "kafka" (include "kafka.config" $nodeHelperCTX | fromYaml) -}}

      {{- $_ := set $parsedNodeValues "volumeMounts" (include "smilecdr.volumeMounts" $nodeHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedNodeValues "volumes" (include "smilecdr.volumes" $nodeHelperCTX | fromYamlArray) -}}


      {{- /* $ingressConfig := dict "annotations" (include "ingress.annotations" $nodeHelperCTX | fromYaml) -}}
      {{- $_ := set $ingressConfig "hosts" (include "ingress.hosts" $nodeHelperCTX | fromYamlArray) -}}
      {{- $_ := set $parsedNodeValues "ingress" $ingressConfig */ -}}

      {{- /* $_ := set $nodes $theNodeName $parsedNodeValues */ -}}
      {{- $_ := set $nodes $theNodeName $nodeHelperCTX -}}
    {{- end -}}
  {{- end -}}
  {{- $nodes | toYaml -}}
{{- end -}}
