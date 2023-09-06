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
    {{- range $k, $v := $theNodeSpec.mappedFiles -}}
      {{- /* if and (not (contains $fileCfgMaps $k)) (hasKey $v "data") */ -}}
      {{- if hasKey $v "data" -}}
        {{- $cmDict := (dict "name" ( $k ) "fileName" (default $k $v.fileName) "data" $v.data "hash" ( sha256sum $v.data )) -}}
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
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $cmName := printf "%s-scdr-%s" $.Release.Name ($k | replace "." "-") -}}
      {{- if and $.Values.autoDeploy (hasKey $v "data") -}}
        {{- $cmName = printf "%s-%s" $cmName (sha256sum ($v.data)) -}}
      {{- end -}}
      {{- $fileVolume := dict "name" ($k | replace "." "-") -}}
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
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $fileVolumeMount := dict "name" ($k | replace "." "-") -}}
      {{- $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $v.path) (default $k $v.fileName)) -}}
      {{- /* $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $v.path) $k) */ -}}
      {{- /* $_ := set $fileVolumeMount "subPath" $k */ -}}
      {{- $_ := set $fileVolumeMount "subPath" (default $k $v.fileName) -}}
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
    {{- range $v := $classesFileSources -}}
      {{- if eq $v.type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy classes files from." $v.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy classes files from." $v.path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $imageSpec := dict "name" "init-pull-classes-s3" -}}
        {{- $_ := set $imageSpec "image" $.Values.copyFiles.config.awscli.image -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/classes/" "--recursive" )  -}}
        {{- $awsCliPodSecurityContext := deepCopy $.Values.securityContext -}}
        {{- $_ := set $awsCliPodSecurityContext "runAsUser" $.Values.copyFiles.config.awscli.runAsUser -}}
        {{- $_ := set $imageSpec "securityContext" $awsCliPodSecurityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/") (dict "name" "aws-cli" "mountPath" "/.aws")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else if eq $v.type "curl" -}}
        {{- $url := required "You must specify a URL to copy classes files from." $v.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for classes files." $v.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/classes/%s" $fileName -}}
        {{- $imageSpec := dict "name" "init-pull-classes-curl" -}}
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
    {{- range $v := $customerlibFileSources -}}
      {{- if eq .type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy customerlib files from." $v.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy customerlib files from." $v.path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $imageSpec := dict "name" "init-pull-customerlib-s3" -}}
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
        {{- $url := required "You must specify a URL to copy customerlib files from." $v.url -}}
        {{- $fileName := required "You must specify a destination `fileName` for customerlib files." $v.fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/customerlib/%s" $fileName -}}
        {{- $imageSpec := dict "name" "init-pull-customerlib-curl" -}}
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
