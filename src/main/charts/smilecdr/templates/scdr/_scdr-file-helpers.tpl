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
Define fileVolumes for all mapped files
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
Define fileVolumeMounts for all mapped files
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
  {{- if not (.Values.messageBroker.external.config.authentication).disableAutoJarCopy -}}
    {{- $customerlibFileSources = concat $customerlibFileSources (include "kafka.customerlib.sources" . | fromYamlArray) -}}
  {{- end -}}

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
  {{- $initContainerResources := (dict "requests" (dict "cpu" "500m" "memory" "500Mi")) -}}
  {{- $_ := set $initContainerResources "limits" (dict "cpu" "500m" "memory" "500Mi") -}}
  {{- $classesFileSources := (include "smilecdr.classes.sources" . | fromYamlArray ) -}}
  {{- $customerlibFileSources := (include "smilecdr.customerlib.sources" . | fromYamlArray ) -}}

  {{- /* Define init containers for classes directory syncing/copying
         Only run if there are files to copy to classes directory */ -}}
  {{- if or (ne (len $classesFileSources) 0) (hasKey .Values "license") -}}
    {{- if not ((.Values.copyFiles.classes).disableSyncDefaults) -}}
      {{- $imageSpec := dict "name" "init-sync-classes" -}}
      {{- $_ := set $imageSpec "image" (printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag)) -}}
      {{- $_ := set $imageSpec "imagePullPolicy" .Values.image.pullPolicy -}}
      {{- $_ := set $imageSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/classes/* /tmp/smilecdr-volumes/classes/")  -}}
      {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
      {{- $initPullContainers = append $initPullContainers $imageSpec -}}
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
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($bucketFullPath | sha256sum | trunc 32)) "" (gt $classesS3SourceCount 1) -}}
        {{- $imageSpec := dict "name" (printf "init-pull-classes-s3%s" $imageNameSuffix ) -}}
        {{- $_ := set $imageSpec "image" $.Values.copyFiles.config.awscli.image -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/classes/" "--recursive" )  -}}
        {{- $awsCliPodSecurityContext := deepCopy $.Values.securityContext -}}
        {{- $_ := set $awsCliPodSecurityContext "runAsUser" $.Values.copyFiles.config.awscli.runAsUser -}}
        {{- $_ := set $imageSpec "securityContext" $awsCliPodSecurityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else if eq $theFileSource.type "curl" -}}
        {{- $url := required "You must specify a URL to copy classes files from." $theFileSource.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for classes files." $theFileSource.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/classes/%s" $fileName -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $classesCurlSourceCount 1) -}}
        {{- $imageSpec := dict "name" (printf "init-pull-classes-curl%s" $imageNameSuffix ) -}}
        {{- $_ := set $imageSpec "image" $.Values.copyFiles.config.curl.image -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $curlPodSecurityContext := deepCopy $.Values.securityContext -}}
        {{- $_ := set $curlPodSecurityContext "runAsUser" $.Values.copyFiles.config.curl.runAsUser -}}
        {{- $_ := set $imageSpec "securityContext" $curlPodSecurityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for customerlib directory syncing/copying
         Only run if there are files to copy to customerlib directory */ -}}
  {{- if ne (len $customerlibFileSources) 0 -}}
    {{- if not ((.Values.copyFiles.customerlib).disableSyncDefaults) -}}
      {{- $imageSpec := dict "name" "init-sync-customerlib" -}}
      {{- $_ := set $imageSpec "image" (printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag)) -}}
      {{- $_ := set $imageSpec "imagePullPolicy" .Values.image.pullPolicy -}}
      {{- $_ := set $imageSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/customerlib/* /tmp/smilecdr-volumes/customerlib/")  -}}
      {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
      {{- $initPullContainers = append $initPullContainers $imageSpec -}}
    {{- end -}}
    {{- /* Get counts of s3 & curl sources for customerlib dir.
        We don't need to append hash if there is only a single source of each type */ -}}
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
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($bucketFullPath | sha256sum | trunc 32)) "" (gt $customerlibS3SourceCount 1) -}}
        {{- $imageSpec := dict "name" (printf "init-pull-customerlib-s3%s" $imageNameSuffix ) -}}
        {{- $_ := set $imageSpec "image" $.Values.copyFiles.config.awscli.image -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/customerlib/" "--recursive" )  -}}
        {{- $awsCliPodSecurityContext := deepCopy $.Values.securityContext -}}
        {{- $_ := set $awsCliPodSecurityContext "runAsUser" $.Values.copyFiles.config.awscli.runAsUser -}}
        {{- $_ := set $imageSpec "securityContext" $awsCliPodSecurityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else if eq .type "curl" -}}
        {{- $url := required "You must specify a URL to copy customerlib files from." $theFileSource.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for customerlib files." $theFileSource.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/customerlib/%s" $fileName -}}
        {{- /* Only append hash if there is more than one S3 init-pull container for the classes dir */ -}}
        {{- $imageNameSuffix := ternary (printf "-%s" ($fileFullPath | sha256sum | trunc 32)) "" (gt $customerlibCurlSourceCount 1) -}}
        {{- $imageSpec := dict "name" (printf "init-pull-customerlib-curl%s" $imageNameSuffix ) -}}
        {{- $_ := set $imageSpec "image" $.Values.copyFiles.config.curl.image -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $curlPodSecurityContext := deepCopy $.Values.securityContext -}}
        {{- $_ := set $curlPodSecurityContext "runAsUser" $.Values.copyFiles.config.curl.runAsUser -}}
        {{- $_ := set $imageSpec "securityContext" $curlPodSecurityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for license copying.
         Sync container was already defined above if there was a license. */ -}}
  {{- if hasKey .Values "license" -}}
    {{- $imageSpec := dict "name" "copy-cdr-license" -}}
    {{- $_ := set $imageSpec "image" "alpine:3" -}}
    {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
    {{- $_ := set $imageSpec "args" (list "cp" "/mnt/sscsi/license.jwt" "/tmp/smilecdr-volumes/classes/" )  -}}
    {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
    {{- $_ := set $imageSpec "resources" $initContainerResources -}}
    {{- $_ := set $imageSpec "volumeMounts" (append (include "smilecdr.volumeMounts" . | fromYamlArray) (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
    {{- $initPullContainers = append $initPullContainers $imageSpec -}}
  {{- end -}}
  {{- $initPullContainers | toYaml -}}
{{ end }}
