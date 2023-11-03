{{/*
These helper templates are used to help import files into the environment
using ConfigMaps
*/}}

{{- /*
This template helps create a configMap for each file that is defined in the
.Values.mappedFiles section.
It expects that there should also be a .Values.mappedFiles.filename.data section
that contains the file contents, as passed in by the --set-file helm install option.
We loop through the nodes as we only want to include any files that are actually in
use by a node.
*/ -}}
{{- define "smilecdr.fileConfigMaps" -}}
{{- $fileCfgMaps := list -}}
{{- range $theNodeName, $theNodeCtx := include "smilecdr.nodes" . | fromYaml -}}
  {{- $theNodeSpec := $theNodeCtx.Values -}}
  {{- if gt (len $theNodeSpec.mappedFiles) 0 -}}
    {{- range $theMappedFileKey, $theMappedFile := $theNodeSpec.mappedFiles -}}
      {{- /* if and (not (contains $fileCfgMaps $theMappedFileKey)) (hasKey $theMappedFile "data") */ -}}
      {{- if hasKey $theMappedFile "data" -}}
        {{- $cmDict := (dict "name" ( $theMappedFileKey ) "fileName" (default $theMappedFileKey $theMappedFile.fileName) "data" $theMappedFile.data "hash" ( sha256sum $theMappedFile.data )) -}}
        {{- if not (has $cmDict $fileCfgMaps ) -}}
          {{- $fileCfgMaps = append $fileCfgMaps $cmDict -}}
        {{- end -}}
      {{- else -}}
        {{- /* fail "No data. fix this error" */ -}}
        {{- /* TODO: fix... */ -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $fileCfgMaps | toYaml -}}
{{- end -}}

{{/*
Define fileVolumes for user defined mapped files
*/}}
{{ define "smilecdr.fileVolumes" }}
  {{- $fileVolumes := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $theMappedFileKey, $theMappedFile := .Values.mappedFiles -}}
      {{- $cmName := printf "%s-scdr-%s" $.Release.Name ($theMappedFileKey | replace "." "-") -}}
      {{- if and $.Values.autoDeploy (hasKey $theMappedFile "data") -}}
        {{- $cmName = printf "%s-%s" $cmName (sha256sum ($theMappedFile.data)) -}}
      {{- end -}}
      {{- $fileVolume := dict "name" ($theMappedFileKey | replace "." "-") -}}
      {{- $_ := set $fileVolume "configMap" (dict "name" $cmName) -}}
      {{- $fileVolumes = append $fileVolumes $fileVolume -}}
    {{- end -}}
  {{- end -}}
  {{- /* Add init-sync shared volumes for classes and customerlib if enabled */ -}}
  {{- if or (ne (len (include "smilecdr.classes.sources" . | fromYamlArray)) 0) (hasKey .Values "license") -}}
    {{- $fileVolume := dict "name" "scdr-volume-classes" -}}
    {{- $_ := set $fileVolume "emptyDir" (dict "sizeLimit" "500Mi") -}}
    {{- $fileVolumes = append $fileVolumes $fileVolume -}}
  {{- end -}}
  {{- if (ne (len (include "smilecdr.customerlib.sources" . | fromYamlArray)) 0) -}}
    {{- $fileVolume := dict "name" "scdr-volume-customerlib" -}}
    {{- $_ := set $fileVolume "emptyDir" (dict "sizeLimit" "500Mi") -}}
    {{- $fileVolumes = append $fileVolumes $fileVolume -}}
  {{- end -}}
  {{- $fileVolumes | toYaml -}}
{{- end -}}

{{/*
Define fileVolumeMounts for user defined mapped files
*/}}
{{ define "smilecdr.fileVolumeMounts" }}
  {{- $fileVolumeMounts := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $theMappedFileKey, $theMappedFile := .Values.mappedFiles -}}
      {{- $fileVolumeMount := dict "name" ($theMappedFileKey | replace "." "-") -}}
      {{- $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $theMappedFile.path) (default $theMappedFileKey $theMappedFile.fileName)) -}}
      {{- /* $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $theMappedFile.path) $theMappedFileKey) */ -}}
      {{- /* $_ := set $fileVolumeMount "subPath" $theMappedFileKey */ -}}
      {{- $_ := set $fileVolumeMount "subPath" (default $theMappedFileKey $theMappedFile.fileName) -}}
      {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- /* Add init-sync shared volumes for classes and customerlib if enabled */ -}}
  {{- if or (ne (len (include "smilecdr.classes.sources" . | fromYamlArray)) 0) (hasKey .Values "license") -}}
    {{- $fileVolumeMount := dict "name" "scdr-volume-classes" -}}
    {{- $_ := set $fileVolumeMount "mountPath" "/home/smile/smilecdr/classes" -}}
    {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
  {{- end -}}
  {{- if (ne (len (include "smilecdr.customerlib.sources" . | fromYamlArray)) 0) -}}
    {{- $fileVolumeMount := dict "name" "scdr-volume-customerlib" -}}
    {{- $_ := set $fileVolumeMount "mountPath" "/home/smile/smilecdr/customerlib" -}}
    {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
  {{- end -}}
  {{- $fileVolumeMounts | toYaml -}}
{{ end }}

{{/*
Collated list of all files to copy to classes dir
*/}}
{{ define "smilecdr.classes.sources" }}

  {{- /* Add files defined in values file */ -}}
  {{- $classesFileSources := (default (list) (((.Values.copyFiles).classes).sources)) -}}

    {{- /* We can add code here if there are any other files that we want the chart to
         automagically download based on feature flags.
         See the `smilecdr.customerlib.sources` helper template below for an example. */ -}}

  {{- $classesFileSources | toYaml  -}}
{{- end -}}

{{/*
Collated list of all files to copy to customerlib dir
*/}}
{{ define "smilecdr.customerlib.sources" }}

  {{- /* Add files defined in values file */ -}}
  {{- $customerlibFileSources := (default (list) (((.Values.copyFiles).customerlib).sources)) -}}

  {{- /* We can add code here if there are any other files that we want the chart to
         automagically download based on feature flags.
         Note: If a particular set of files need to be used in separate pod configurations,
         it is worth defining them in a template, to avoid code duplication, and including
         them like below */ -}}

  {{- /* Add files required by Kafka (e.g. MSK IAM Jar) */ -}}
  {{- /* Currently, this template only supports the AWS MSK IAM jar file.
         If it's not required (maybe the user has included it in their custom image)
         then there is no need to include here.
         Doing the exclusion logic here rather than in the helper template itself, as the
         file still needs to be defined for use by the Kafka Admin pod deployment */ -}}
  {{- /* if not (.Values.messageBroker.external.config.authentication).disableAutoJarCopy */ -}}
  {{- $customerlibFileSources = concat $customerlibFileSources (include "kafka.customerlib.sources" . | fromYamlArray) -}}
  {{- /* end */ -}}

  {{- /* Add files required by observability tooling (e.g. Dependencies for included interceptor modules.) */ -}}
  {{- $customerlibFileSources = concat $customerlibFileSources (include "observability.customerlib.sources" . | fromYamlArray) -}}

  {{- $customerlibFileSources | toYaml  -}}
{{- end -}}

{{/*
Define init-pull containers

Note:
We are defining volumeMounts for these init containers directly rather than in smilecdr.fileVolumeMounts
because these init containers do not need any of the files mapped by configMaps.
Volumes are defined in `smilecdr.fileVolumes`
*/}}
{{ define "smilecdr.initFileContainers" }}
  {{- $initPullContainers := list -}}

  {{- $classesFileSources := (include "smilecdr.classes.sources" . | fromYamlArray ) -}}
  {{- $customerlibFileSources := (include "smilecdr.customerlib.sources" . | fromYamlArray ) -}}

  {{- /* Set up config for initContainers */ -}}
  {{- $syncContainerSpec := dict -}}
  {{- $s3ContainerSpec := dict -}}
  {{- $curlContainerSpec := dict -}}
  {{- $utilsContainerSpec := dict -}}

  {{- $defaultResources := dict -}}
  {{- $_ := set $defaultResources "requests" (dict "cpu" "500m" "memory" "500Mi") -}}
  {{- $_ := set $defaultResources "limits" (dict "cpu" "500m" "memory" "500Mi") -}}

  {{- $syncConfig := dict -}}
  {{- $_ := set $syncContainerSpec "image" (printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag)) -}}
  {{- $_ := set $syncContainerSpec "imagePullPolicy" (default "IfNotPresent" .Values.image.pullPolicy) -}}
  {{- $_ := set $syncContainerSpec "securityContext" (deepCopy .Values.securityContext) -}}
  {{- $_ := set $syncContainerSpec "resources" $defaultResources -}}

  {{- $s3Config := ternary ((.Values.copyFiles).config).s3 dict (hasKey ((.Values.copyFiles).config) "s3") -}}
  {{- $defaultS3ImageTag := "2.13.19" -}}
  {{- $defaultS3ImageRepo := "public.ecr.aws/aws-cli/aws-cli" -}}
  {{- $defaultS3ImageUser := 1000 -}}
  {{- $_ := set $s3ContainerSpec "image" (printf "%s:%s" (default $defaultS3ImageRepo $s3Config.repository) (default $defaultS3ImageTag $s3Config.tag)) -}}
  {{- $_ := set $s3ContainerSpec "imagePullPolicy" (default "IfNotPresent" $s3Config.imagePullPolicy) -}}
  {{- $_ := set $s3ContainerSpec "securityContext" (mergeOverwrite (deepCopy .Values.securityContext) (default (dict "runAsUser" $defaultS3ImageUser) $s3Config.securityContext)) -}}
  {{- $_ := set $s3ContainerSpec "resources" (default $defaultResources $s3Config.resources) -}}

  {{- $curlConfig := ternary ((.Values.copyFiles).config).curl dict (hasKey ((.Values.copyFiles).config) "curl") -}}
  {{- $defaultCurlImageTag := "8.1.2" -}}
  {{- $defaultCurlImageRepo := "quay.io/curl/curl" -}}
  {{- $defaultCurlImageUser := 100 -}}
  {{- $_ := set $curlContainerSpec "image" (printf "%s:%s" (default $defaultCurlImageRepo $curlConfig.repository) (default $defaultCurlImageTag $curlConfig.tag)) -}}
  {{- $_ := set $curlContainerSpec "imagePullPolicy" (default "IfNotPresent" $curlConfig.imagePullPolicy) -}}
  {{- $_ := set $curlContainerSpec "securityContext" (mergeOverwrite (deepCopy .Values.securityContext) (default (dict "runAsUser" $defaultCurlImageUser) $curlConfig.securityContext)) -}}
  {{- $_ := set $curlContainerSpec "resources" (default $defaultResources $curlConfig.resources) -}}

  {{- $utilsConfig := ternary ((.Values.copyFiles).config).utils dict (hasKey ((.Values.copyFiles).config) "utils") -}}
  {{- $defaultUtilsImageTag := "3" -}}
  {{- $defaultUtilsImageRepo := "public.ecr.aws/docker/library/alpine" -}}
  {{- $defaultUtilsImageUser := 100 -}}
  {{- $_ := set $utilsContainerSpec "image" (printf "%s:%s" (default $defaultUtilsImageRepo $utilsConfig.repository) (default $defaultUtilsImageTag $utilsConfig.tag)) -}}
  {{- $_ := set $utilsContainerSpec "imagePullPolicy" (default "IfNotPresent" .Values.image.pullPolicy) -}}
  {{- $_ := set $utilsContainerSpec "securityContext" (mergeOverwrite (deepCopy .Values.securityContext) (default (dict "runAsUser" $defaultUtilsImageUser) $utilsConfig.securityContext)) -}}
  {{- $_ := set $utilsContainerSpec "resources" (default $defaultResources $utilsConfig.resources) -}}

  {{- /* Define init containers for classes directory syncing/copying
         Only run if there are files to copy to classes directory */ -}}
  {{- if or (ne (len $classesFileSources) 0) (hasKey .Values "license") -}}
    {{- if not ((.Values.copyFiles.classes).disableSyncDefaults) -}}
      {{- $containerSpec := deepCopy (omit $syncContainerSpec "repository" "tag") -}}
      {{- $_ := set $containerSpec "name" "init-sync-classes" -}}
      {{- $_ := set $containerSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/classes/* /tmp/smilecdr-volumes/classes/")  -}}
      {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
      {{- $initPullContainers = append $initPullContainers $containerSpec -}}
    {{- end -}}
    {{- /* Get counts of s3 & curl sources for classes dir.
        We don't need to append hash if there is only a single source of each type */ -}}
    {{- $classesS3SourceCount := 0 -}}
    {{- $classesCurlSourceCount := 0 -}}
    {{- range $theFileSource := $classesFileSources -}}
      {{- if eq $theFileSource.type "s3" -}}
        {{- $classesS3SourceCount = add $classesS3SourceCount 1 -}}
      {{- else if eq $theFileSource.type "curl" -}}
        {{- $classesCurlSourceCount = add $classesCurlSourceCount 1 -}}
      {{- end -}}
    {{- end -}}
    {{- range $theFileSource := $classesFileSources -}}
      {{- if eq $theFileSource.type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy classes files from." $theFileSource.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy classes files from." $theFileSource.path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $containerSpec := deepCopy (omit $s3ContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($bucketFullPath | sha256sum | trunc 32)) "" (gt $classesS3SourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-classes-s3%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/classes/" "--recursive" )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else if eq $theFileSource.type "curl" -}}
        {{- $url := required "You must specify a URL to copy classes files from." $theFileSource.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for classes files." $theFileSource.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/classes/%s" $fileName -}}
        {{- $containerSpec := deepCopy (omit $curlContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $classesCurlSourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-classes-curl%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for customerlib directory syncing/copying
         Only run if there are files to copy to customerlib directory */ -}}
  {{- if ne (len $customerlibFileSources) 0 -}}
    {{- if not ((.Values.copyFiles.customerlib).disableSyncDefaults) -}}
      {{- $containerSpec := deepCopy (omit $syncContainerSpec "repository" "tag") -}}
      {{- $_ := set $containerSpec "name" "init-sync-customerlib" -}}
      {{- $_ := set $containerSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/customerlib/* /tmp/smilecdr-volumes/customerlib/")  -}}
      {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
      {{- $initPullContainers = append $initPullContainers $containerSpec -}}
    {{- end -}}
    {{- /* Get counts of s3 & curl sources for customerlib dir.
        We only need to append hash if there are multiple sources of each type
        so that we can avoid container name collisions */ -}}
    {{- $customerlibS3SourceCount := 0 -}}
    {{- $customerlibCurlSourceCount := 0 -}}
    {{- range $theFileSource := $customerlibFileSources -}}
      {{- if eq $theFileSource.type "s3" -}}
        {{- $customerlibS3SourceCount = add $customerlibS3SourceCount 1 -}}
      {{- else if eq $theFileSource.type "curl" -}}
        {{- $customerlibCurlSourceCount = add $customerlibCurlSourceCount 1 -}}
      {{- end -}}
    {{- end -}}
    {{- range $theFileSource := $customerlibFileSources -}}
      {{- if eq .type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy customerlib files from." $theFileSource.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy customerlib files from." $theFileSource.path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $containerSpec := deepCopy (omit $s3ContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($bucketFullPath | sha256sum | trunc 32)) "" (gt $customerlibS3SourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-customerlib-s3%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/customerlib/" "--recursive" )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else if eq .type "curl" -}}
        {{- $url := required "You must specify a URL to copy customerlib files from." $theFileSource.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for customerlib files." $theFileSource.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/customerlib/%s" $fileName -}}
        {{- $containerSpec := deepCopy (omit $curlContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one curl init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $customerlibCurlSourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-customerlib-curl%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for java agents */ -}}
  {{- $javaAgentSources := (include "observability.javaagent.sources" . | fromYamlArray ) -}}
  {{- if ne (len $javaAgentSources) 0 -}}
    {{- /* Get counts of s3 & curl sources for java agent dir.
        We only need to append hash if there are multiple sources of each type
        so that we can avoid container name collisions */ -}}
    {{- $javaAgentS3SourceCount := 0 -}}
    {{- $javaAgentCurlSourceCount := 0 -}}
    {{- range $theFileSource := $javaAgentSources -}}
      {{- if eq $theFileSource.type "s3" -}}
        {{- $javaAgentS3SourceCount = add $javaAgentS3SourceCount 1 -}}
      {{- else if eq $theFileSource.type "curl" -}}
        {{- $javaAgentCurlSourceCount = add $javaAgentCurlSourceCount 1 -}}
      {{- end -}}
    {{- end -}}
    {{- range $theFileSource := $javaAgentSources -}}
      {{- if eq .type "s3" -}}
        {{- $containerSpec := deepCopy (omit $s3ContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the java agent dir */ -}}
        {{- $fileFullPath := "/tmp/smilecdr-volumes/javaagent/" -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $javaAgentS3SourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-javaagent-s3%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "s3" "cp" $theFileSource.url $fileFullPath "--recursive" )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-javaagent" "mountPath" "/tmp/smilecdr-volumes/javaagent/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else if eq .type "curl" -}}
        {{- $url := required "You must specify a URL to copy java agent files from." $theFileSource.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for java agent files." $theFileSource.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/javaagent/%s" $fileName -}}
        {{- $containerSpec := deepCopy (omit $curlContainerSpec "repository" "tag") -}}
        {{- /* Only append hash if there is more than one curl init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $javaAgentCurlSourceCount 1) -}}
        {{- $_ := set $containerSpec "name" (printf "init-pull-javaagent-curl%s" $imageNameSuffix ) -}}
        {{- $_ := set $containerSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $_ := set $containerSpec "volumeMounts" (list (dict "name" "scdr-volume-javaagent" "mountPath" "/tmp/smilecdr-volumes/javaagent/")) -}}
        {{- $initPullContainers = append $initPullContainers $containerSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for license copying.
         Using the Smile CDR image as it's already present on the node
         and will do what is needed.
        */ -}}
  {{- if hasKey .Values "license" -}}
    {{- $containerSpec := deepCopy (omit $syncContainerSpec "repository" "tag") -}}
    {{- $_ := set $containerSpec "name" "copy-cdr-license" -}}
    {{- $_ := set $containerSpec "command" (list "/bin/sh" "-c") -}}
    {{- $_ := set $containerSpec "args" (list "/bin/cp /mnt/sscsi/license.jwt /tmp/smilecdr-volumes/classes/") -}}
    {{- $_ := set $containerSpec "volumeMounts" (append (include "smilecdr.volumeMounts" . | fromYamlArray) (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
    {{- $initPullContainers = append $initPullContainers $containerSpec -}}
  {{- end -}}
  {{- $initPullContainers | toYaml -}}
{{ end }}
